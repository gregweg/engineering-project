class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true
  has_many :anomalies, class_name: "TransactionAnomaly", foreign_key: :txn_id, dependent: :destroy

  validates :date, presence: true
  validates :amount, presence: true, numericality: true

  scope :flagged, -> { where(needs_review: true) }
  scope :unflagged, -> { where(needs_review: false) }
  scope :uncategorized, -> { where(category_id: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :with_amount_range, ->(min, max) { where(amount: min..max) }

  def flag_types
    Rails.cache.fetch("transaction_#{id}_flag_types", expires_in: 5.minutes) do
      anomalies.where(resolved: false).pluck(:flag_type).uniq
    end
  end

  def self.user_spending_stats(user_id, days = 30)
    Rails.cache.fetch("user_#{user_id}_spending_stats_#{days}d", expires_in: 1.hour) do
      transactions = where(user_id: user_id, date: days.days.ago..Date.current)
      {
        total_amount: transactions.sum(:amount),
        transaction_count: transactions.count,
        avg_amount: transactions.average(:amount)&.round(2),
        categories: transactions.joins(:category).group('categories.name').sum(:amount)
      }
    end
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
