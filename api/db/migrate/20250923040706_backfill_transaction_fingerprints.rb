require "digest"
class BackfillTransactionFingerprints < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    say_with_time "Backfilling transaction fingerprints" do
      Transaction.where(fingerprint: nil).find_in_batches(batch_size: 1000) do |batch|
        updates = batch.map do |t|
          norm_desc = t.description.to_s.downcase.strip.gsub(/\s+/, " ")
          d = t.date&.iso8601.to_s
          a = t.amount&.to_s || ""
          u = t.user_id.to_s
          fp = Digest::MD5.hexdigest([u, d, a, norm_desc].join("|"))
          [t.id, fp]
        end
        # bulk update (AR upsert if you like, or do individual updates)
        updates.each { |id, fp| Transaction.where(id: id).update_all(fingerprint: fp) }
      end
    end
  end

  def down; end
end