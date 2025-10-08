class CsvImportJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 1000

  def perform(batch_id, temp_path)
    batch = ImportBatch.find(batch_id)
    user  = batch.user

    batch.update!(status: "processing")

    require "csv"
    processed = 0
    to_upsert = []
    errors = []

    CSV.foreach(temp_path, headers: true) do |row|
      raw = row.to_h.transform_keys { |k| k.to_s.downcase.strip }
      begin
        date  = Date.iso8601(raw["date"].to_s.strip)
        # normalize amount like $1,234.56
        amount_clean = raw["amount"].to_s.strip.gsub(/[^\d\.\-]/, "")
        raise ArgumentError, "bad amount" unless amount_clean.match?(/\A-?\d+(\.\d+)?\z/)
        amount = BigDecimal(amount_clean)
        desc   = raw["description"].to_s

        cat_id = nil
        if (category_name = raw["category"].presence)
          cat = user.categories
                    .where("LOWER(name)=?", category_name.downcase)
                    .first_or_create!(name: category_name)
          cat_id = cat.id
        end

        fp = TxnUtils.fingerprint(
          user_id: user.id, date: date, amount: amount, description: desc
        )

        to_upsert << {
          user_id: user.id,
          date: date,
          amount: amount,
          description: desc,
          category_id: cat_id,
          metadata: {},
          fingerprint: fp,
          needs_review: false,
          created_at: Time.current,
          updated_at: Time.current
        }

        if to_upsert.size >= BATCH_SIZE
          Transaction.upsert_all(to_upsert, unique_by: %i[user_id fingerprint])
          processed += to_upsert.size
          to_upsert.clear
          batch.update!(processed_rows: processed)
        end
      rescue => e
        errors << { row: row.to_h, error: e.message }
      end
    end

    if to_upsert.any?
      Transaction.upsert_all(to_upsert, unique_by: %i[user_id fingerprint])
      processed += to_upsert.size
    end

    batch.update!(processed_rows: processed, total_rows: processed + errors.size,
                  status: "done", error_messages: errors)

    # kick off rules + anomalies
    RuleApplyJob.perform_later(user.id)
    AnomalyScanJob.perform_later(user.id)

  rescue => e
    batch.update!(status: "failed")
    Rails.logger.error("CSV import failed for batch #{batch_id}: #{e.class}: #{e.message}")
  ensure
    # best-effort: remove temp file
    File.delete(temp_path) rescue nil
  end
end