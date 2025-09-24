class TransactionCacheService
  CACHE_EXPIRY = 1.hour

  def self.user_summary(user_id)
    Rails.cache.fetch("user_#{user_id}_summary", expires_in: CACHE_EXPIRY) do
      user = User.find(user_id)
      {
        total_transactions: user.transactions.count,
        flagged_count: user.transactions.flagged.count,
        uncategorized_count: user.transactions.uncategorized.count,
        total_amount: user.transactions.sum(:amount),
        categories_count: user.categories.count
      }
    end
  end

  def self.transaction_anomaly_counts(user_id)
    Rails.cache.fetch("user_#{user_id}_anomaly_counts", expires_in: CACHE_EXPIRY) do
      TransactionAnomaly.joins(transaction: :user)
                        .where(users: { id: user_id }, resolved: false)
                        .group(:flag_type)
                        .count
    end
  end

  def self.recent_transactions(user_id, limit = 50)
    Rails.cache.fetch("user_#{user_id}_recent_#{limit}", expires_in: 5.minutes) do
      Transaction.includes(:category, :anomalies)
                 .where(user_id: user_id)
                 .recent
                 .limit(limit)
                 .as_json(
                   only: [:id, :date, :description, :amount, :needs_review],
                   include: {
                     category: { only: [:id, :name, :color] },
                     anomalies: { only: [:flag_type, :resolved] }
                   }
                 )
    end
  end

  def self.clear_user_cache(user_id)
    pattern = "user_#{user_id}_*"
    keys = Rails.cache.redis.keys(pattern)
    Rails.cache.delete_multi(keys) if keys.any?
  end

  def self.clear_transaction_cache(transaction_id)
    Rails.cache.delete("transaction_#{transaction_id}_flag_types")
  end
end