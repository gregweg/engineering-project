class V1::TransactionsController < ApplicationController
    before_action :set_user
    before_action :find_txn, only: [ :show, :flag, :unflag, :flag_type, :unflag_type, :update_flag, :destroy ]

    def index
      txns = @user.transactions.includes(:category).limit(params[:limit] || 100)

      render json: txns.as_json(
        only: [ :id, :date, :description, :amount, :needs_review ],
        methods: [],
        include: {
          category: { only: [ :id, :name ] }
        }
      )
    end

    def show
      render json: @txn.as_json(
        only: [ :id, :date, :description, :amount, :needs_review, :fingerprint, :metadata, :created_at, :updated_at ],
        include: {
          category: { only: [ :id, :name, :color ] },
          anomalies: {
            only: [ :id, :flag_type, :details, :resolved, :created_at ],
            methods: [ :message ]
          }
        }
      )
    end

    def create
       # Strong params → plain Ruby hash with symbol keys
      attrs = txn_params.to_h.symbolize_keys

       # Presence check first (nil or empty string)
      required = %i[date amount description]
      missing  = required.select { |k| attrs[k].blank? }
      if missing.any?
       return render json: { error: "Missing required fields", fields: missing }, status: :unprocessable_content
      end

      # Parse date strictly as YYYY-MM-DD
      begin
        date = Date.iso8601(attrs[:date].to_s.strip)
      rescue ArgumentError
        return render json: { error: "Invalid date format", hint: "Use YYYY-MM-DD", value: attrs[:date] }, status: :unprocessable_content
      end

      # Parse amount: allow "$1,234.56" or "1234.56" or 1234.56
      begin
        raw_amount = attrs[:amount]
        amount_str =
          case raw_amount
          when Numeric then raw_amount.to_s
          else raw_amount.to_s
          end

        # remove currency symbols and thousands separators
        amount_clean = amount_str.strip.gsub(/[^\d\.\-]/, "")
        # ensure looks like a number
        unless amount_clean.match?(/\A-?\d+(\.\d+)?\z/)
          raise ArgumentError, "not a decimal"
        end

        amount = BigDecimal(amount_clean)
      rescue ArgumentError
        return render json: { error: "Invalid amount format", hint: "Examples: 49.99, 1,234.56, $12.00", value: attrs[:amount] }, status: :unprocessable_content
      end

      description = attrs[:description].to_s
      category_id = attrs[:category_id].presence
      metadata    = attrs[:metadata].is_a?(Hash) ? attrs[:metadata] : {}

      fp = TxnUtils.fingerprint(
        user_id: @user.id,
        date: date,
        amount: amount,
        description: description
      )

      txn = @user.transactions.create_with(
        date: date,
        amount: amount,
        description: description,
        category_id: category_id,
        metadata: attrs[:metadata].presence || {}
      ).find_or_create_by!(fingerprint: fp)

      # enqueue jobs (or keep inline adapter while Redis isn’t set)
      RuleEngine.new(@user).apply!(scope: @user.transactions.where(id: txn.id))
      AnomalyScanJob.perform_later(@user.id)

      render json: txn, status: :created
    rescue ArgumentError, Date::Error
      render json: { error: "Invalid date or amount format" }, status: :unprocessable_entity
    end

    def import_csv
      file = params[:file]
      return render json: { error: "file is required" }, status: :bad_request unless file
  
      importer = CsvTransactionImporter.new(@user)
      summary  = importer.import_io(file.tempfile, filename: file.original_filename)
  
      render json: {
        total_rows: summary.total,
        inserted:   summary.inserted,
        flagged:    summary.flagged,
        errors:     summary.errors.first(20) # clip noisy messages
      }
    end

    def bulk_update
      ids = params.require(:ids)
      if params[:category_name]
        cat = @user.categories.where("lower(name)=?", params[:category_name].downcase).first_or_create!(name: params[:category_name])
        @user.transactions.where(id: ids).update_all(category_id: cat.id)
      end
      if params[:clear_flags]
        @user.transactions.where(id: ids).update_all(needs_review: false)
       AnomalyFlag.where(transaction_id: ids).update_all(resolved: true)
      end
      head :no_content
    end

    def review
      render json: {
        uncategorized: @user.transactions.uncategorized.limit(200),
        flagged: @user.transactions.flagged.limit(200)
      }
    end

    def update
      txn = @user.transactions.find(params[:id])
      txn.update!(txn_params)
      head :no_content
    end

    def destroy
      @user.transactions.find(params[:id]).destroy!
      head :no_content
    end

    def bulk_destroy
      ids = Array(params[:ids]).map(&:to_i).uniq
      return render json: { error: "ids required" }, status: :bad_request if ids.empty?

      @user.transactions.where(id: ids).find_each(&:destroy!)
      head :no_content
    end

    def flag
      @txn.update!(needs_review: true)
      begin
        if defined?(TransactionAnomaly)
          @txn.anomalies.find_or_create_by!(flag_type: "missing_metadata", resolved: false) do |a|
            a.details = { source: "manual_flag" }
          end
        end
      rescue => e
        Rails.logger.warn("flag: skipping anomaly create: #{e.class}: #{e.message}")
      end
      render json: { id: @txn.id, needs_review: true }, status: :ok
    end

    def unflag
      @txn.update!(needs_review: false)
      begin
        if defined?(TransactionAnomaly)
          TransactionAnomaly.where(txn_id: @txn.id, resolved: false).update_all(resolved: true)
        end
      rescue => e
        Rails.logger.warn("unflag: skipping anomaly resolution: #{e.class}: #{e.message}")
      end
      render json: { id: @txn.id, needs_review: false }, status: :ok
    rescue => e
      Rails.logger.error("unflag failed: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
      render json: { error: e.message }, status: :internal_server_error
    end

    def bulk_flag
      ids = normalized_ids
      return head :bad_request if ids.empty?
      @user.transactions.where(id: ids).update_all(needs_review: true)
      head :no_content
    end

    def bulk_unflag
      ids = normalized_ids
      return head :bad_request if ids.empty?
      @user.transactions.where(id: ids).update_all(needs_review: false)
      TransactionAnomaly.where(txn_id: ids, resolved: false).update_all(resolved: true)
      head :no_content
    end

     def flags
      ids = Array(params[:ids]).map(&:to_i).uniq
      scope = ids.present? ? @user.transactions.where(id: ids) : @user.transactions.flagged
      data = scope.includes(:anomalies).map do |t|
        flags = t.anomalies.where(resolved: false).map do |a|
          {
            type: a.flag_type,
            message: a.details&.[]("message")
          }
        end
        {
          id: t.id,
          flags: flags
        }
      end
      render json: data
    end

    def flag_type
      type = normalize_flag_type(params[:flag_type])
      msg  = params[:message].to_s.presence
      a = @txn.anomalies.find_or_initialize_by(flag_type: type, resolved: false)
      a.details = (a.details || {}).merge("message" => msg) if msg
      a.resolved = false
      a.save!
      head :no_content
    end

    def unflag_type
      return unless @txn

      type = flag_type_param
      @txn.anomalies.where(flag_type: type, resolved: false).update_all(resolved: true)
      head :no_content
    end

    def update_flag
      return unless @txn

      type = flag_type_param
      msg  = params.require(:message).to_s

      a = @txn.anomalies.where(flag_type: type, resolved: false).first
      if a
        a.update!(details: (a.details || {}).merge("message" => msg))
      else
        @txn.anomalies.create!(
          flag_type: type,
          details: (msg.present? ? { "message" => msg } : {}),
          resolved: false
        )
      end
      head :no_content
    end

    def bulk_unflag_type
      type = normalize_flag_type(params[:flag_type])
      ids  = Array(params[:ids]).map(&:to_i).uniq
      return head :bad_request if ids.empty? || !TransactionAnomaly::FLAG_TYPES.include?(type)

      TransactionAnomaly.where(txn_id: ids, flag_type: type, resolved: false)
                        .update_all(resolved: true)
      # sync parent needs_review in a light pass
      @user.transactions.where(id: ids).find_each do |t|
        has_open = t.anomalies.where(resolved: false).exists?
        t.update_columns(needs_review: has_open)
      end
      head :no_content
    end

  private

  def flag_type_param
    t = params.require(:flag_type).to_s.downcase
    unless TransactionAnomaly::FLAG_TYPES.include?(t)
      render json: { error: "Invalid flag_type" }, status: :bad_request and return
    end
    t
  end

  def set_user
    # Replace with current_user after auth; using first for scaffold
    @user = User.first || User.create!(email: "demo@example.com")
  end

  def txn_params
    params.require(:transaction).permit(:date, :description, :amount, :category_id, metadata: {})
  end

  def find_txn
    @txn = @user.transactions.find_by(id: params[:id])
    return if @txn

    render json: { error: "Transaction not found" }, status: :not_found
  end

  def normalized_ids
    Array(params[:ids]).map(&:to_i).uniq
  end

  def normalize_flag_type(v) = v.to_s.downcase
end
