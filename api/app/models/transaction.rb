class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true
  has_many :anomalies, class_name: "TransactionAnomaly", foreign_key: :txn_id, dependent: :destroy

  validates :date, presence: true
  validates :amount, presence: true, numericality: true

  scope :flagged, -> { where(needs_review: true) }
  scope :unflagged, -> { where(needs_review: false) }

  def flag_types
    anomalies.where(resolved: false).pluck(:flag_type).uniq
  end

  before_save :assign_fingerprint

  private

  def assign_fingerprint
    norm_desc = description.to_s.downcase.strip.gsub(/\s+/, " ")
    # Use ISO date & decimal string; allow blanks so we still get a stable digest
    d = date&.iso8601.to_s
    a = amount.respond_to?(:to_s) ? amount.to_s : amount.to_s
    u = user_id.to_s
    self.fingerprint ||= Digest::MD5.hexdigest([u, d, a, norm_desc].join("|"))
  end
end
