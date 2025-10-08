# app/services/csv_transaction_importer.rb
require "csv"
class CsvTransactionImporter
  Result = Struct.new(:total, :inserted, :flagged, :errors, keyword_init: true)

  # date_formats tried in order; add more if needed
  DATE_FORMATS = [
    "%Y-%m-%d",    # 2025-09-15
    "%m/%d/%Y",    # 09/15/2025
    "%Y/%m/%d",    # 2025/09/15
    "%d-%m-%Y",    # 15-09-2025
  ].freeze

  def initialize(user)
    @user = user
  end

  def import_io(io, filename: nil)
    rows = CSV.new(io, headers: true, return_headers: false).read
    summary = Result.new(total: rows.size, inserted: 0, flagged: 0, errors: [])
    rows.each_with_index do |row, idx|
      begin
        import_row!(row.to_h, idx + 1, summary, filename:)
      rescue => e
        summary.errors << "Row #{idx + 1}: #{e.class} - #{e.message}"
      end
    end
    summary
  end

  def compute_fingerprint(user_id:, date:, amount:, description:)
    TxnUtils.fingerprint(
      user_id: user_id,
      date: date,
      amount: amount,
      description: description
    )
  end

  private

  def import_row!(raw, rownum, summary, filename:)
    raw_date        = (raw["date"] || raw["Date"]).to_s.strip
    raw_desc        = (raw["description"] || raw["Description"]).to_s
    raw_amount      = (raw["amount"] || raw["Amount"]).to_s.strip
    raw_category    = (raw["category"] || raw["Category"]).to_s.strip

    parsed_date, date_err     = parse_date(raw_date)
    parsed_amount, amount_err = parse_amount(raw_amount)

    # Resolve (optional) category by name if provided
    category = nil
    if raw_category.present?
      category = @user.categories.where("LOWER(name) = ?", raw_category.downcase).first
      category ||= @user.categories.create!(name: raw_category) # or skip creating; your choice
    end

    # ⬇️ Compute fp ONCE, reuse everywhere below
    fp = compute_fingerprint(
      user_id:    @user.id,
      date:       parsed_date,
      amount:     parsed_amount,
      description: raw_desc
    )

    # Short-circuit exact duplicates: flag existing & skip insert
    if (existing = @user.transactions.find_by(fingerprint: fp))
      existing.anomalies.find_or_create_by!(flag_type: "duplicate", resolved: false) do |a|
        a.details = {
          "message"      => "Duplicate of existing transaction",
          "source_file"  => filename,
          "rownum"       => rownum
        }
      end
      summary.flagged += 1
      return
    end

    txn = @user.transactions.new(
      date: parsed_date,                       # may be nil
      amount: parsed_amount,                   # may be nil
      description: raw_desc.presence,          # nil if blank/whitespace
      category: category,
      metadata: {
        "import" => {
          "source_file" => filename,
          "rownum"      => rownum,
          "raw_date"    => raw_date,
          "raw_amount"  => raw_amount,
          "raw_category"=> raw_category
        }
      },
      fingerprint: fp
    )

    begin
      txn.save!(validate: false)
    rescue ActiveRecord::RecordNotUnique
      # Race condition: another process inserted the same fingerprint concurrently.
      # Treat as duplicate and move on.
      winner = @user.transactions.find_by(fingerprint: fp)
      unless winner
          # another process may have inserted and then deleted, or this row belongs to a different user
          # treat as a soft skip to avoid nil.anomalies
          summary.errors << "Row #{rownum}: duplicate fingerprint, but winner not found"
          return
      end

      winner.anomalies.find_or_create_by!(flag_type: "duplicate", resolved: false) do |a|
        a.details = { "message" => "Duplicate of existing transaction (race)",
                      "source_file" => filename, "rownum" => rownum }
      end
      summary.flagged += 1
      return
    end
    summary.inserted += 1

    flagged_here = false

    # Missing metadata
    if txn.description.to_s.strip.empty?
      flag!(txn, "missing_metadata", message: "Description is blank")
      flagged_here = true
    end

    # Invalid fields
    if date_err
      flag!(txn, "invalid_date", message: "Could not parse date: #{raw_date}")
      flagged_here = true
    end
    if amount_err
      flag!(txn, "invalid_amount", message: "Could not parse amount: #{raw_amount}")
      flagged_here = true
    end

    # Duplicate: same user/date/amount/normalized description
    if duplicate?(txn)
      flag!(txn, "duplicate", message: "Same date/amount/description as existing transaction")
      flagged_here = true
    end

    # Unusual amount (simple robust detector for the user overall)
    if unusual_amount?(txn)
      flag!(txn, "unusual_amount", message: "Outlier amount vs user history")
      flagged_here = true
    end

    summary.flagged += 1 if flagged_here
  end

  def parse_date(s)
    return [nil, :blank] if s.blank?
    DATE_FORMATS.each do |fmt|
      begin
        return [Date.strptime(s, fmt), nil]
      rescue ArgumentError
        next
      end
    end
    begin
      return [Date.iso8601(s), nil]
    rescue
      # fall through
    end
    [nil, :invalid]
  end

  def parse_amount(s)
    return [nil, :blank] if s.blank?
    t = s.strip
    # normalize commas and currency symbols; support European 1 234,56 and 19,99
    t = t.gsub(/[^\d,.\- ]/, "")      # remove currency letters like $ €
    t = t.gsub(/\s+/, "")             # remove spaces (1 234,56 -> 1234,56)
    if t.count(",") == 1 && t.count(".") == 0
      # treat single comma as decimal separator
      t = t.sub(",", ".")
    else
      # otherwise drop thousands separators
      t = t.gsub(",", "")
    end
    bd = BigDecimal(t)
    [bd, nil]
  rescue
    [nil, :invalid]
  end

  def normalize_desc(s)
    s.to_s.downcase.strip.gsub(/\s+/, " ")
  end

  def duplicate?(txn)
    return false if txn.date.nil? || txn.amount.nil? || txn.description.blank?
    dnorm = normalize_desc(txn.description)
    @user.transactions.where(date: txn.date, amount: txn.amount)
         .where("LOWER(REGEXP_REPLACE(description, '\\s+', ' ', 'g')) = ?", dnorm)
         .where.not(id: txn.id)
         .exists?
  end

  # NOTE: lightweight detector; for 1M+ rows switch to SQL window percentiles
  def unusual_amount?(txn)
    return false unless txn.amount.present?
    amounts = @user.transactions.where.not(amount: nil).limit(5000).pluck(:amount).map(&:to_d)
    return false if amounts.size < 20
    median = percentile(amounts, 0.5)
    mad = median_abs_dev(amounts, median)
    threshold = mad.positive? ? 3.5 : nil
    if threshold
      ((txn.amount - median).abs / mad) > threshold
    else
      mean, std = mean_std(amounts)
      txn.amount > (mean + 3 * std)
    end
  end

  def percentile(arr, p)
    s = arr.sort
    s[(p * (s.length - 1)).round]
  end

  def median_abs_dev(arr, med)
    devs = arr.map { |x| (x - med).abs }
    m = percentile(devs, 0.5)
    m.zero? ? BigDecimal("0") : (m / 0.6745)
  end

  def mean_std(arr)
    mean = arr.sum(0.to_d) / arr.size
    var  = arr.map { |x| (x - mean) ** 2 }.sum(0.to_d) / arr.size
    [mean, BigDecimal(var).sqrt(10)]
  end

  def flag!(txn, type, message:)
    txn.anomalies.find_or_create_by!(flag_type: type, resolved: false) do |a|
      a.details = { "message" => message }
    end
  end
end