module TxnUtils
  module_function
  def normalize_desc(desc)
    desc.to_s.strip.downcase.gsub(/\s+/, " ")
  end
  def fingerprint(user_id:, date:, amount:, description:)
    raw = [user_id, date.to_s, amount.to_s, normalize_desc(description)].join("|")
    Digest::SHA256.hexdigest(raw)
  end
end