class BatchTransactionProcessorJob < ApplicationJob
  queue_as :high_priority

  def perform(user_id, operation, transaction_ids, options = {})
    user = User.find(user_id)
    batch_size = options[:batch_size] || 1000

    transaction_ids.each_slice(batch_size) do |batch_ids|
      case operation
      when 'bulk_categorize'
        bulk_categorize(user, batch_ids, options[:category_id])
      when 'bulk_flag'
        bulk_flag(user, batch_ids)
      when 'bulk_unflag'
        bulk_unflag(user, batch_ids)
      when 'apply_rules'
        apply_rules_batch(user, batch_ids)
      when 'detect_anomalies'
        detect_anomalies_batch(user, batch_ids)
      end

      # Clear cache after each batch
      TransactionCacheService.clear_user_cache(user_id)
    end
  end

  private

  def bulk_categorize(user, transaction_ids, category_id)
    return unless category_id

    user.transactions.where(id: transaction_ids).update_all(
      category_id: category_id,
      updated_at: Time.current
    )
  end

  def bulk_flag(user, transaction_ids)
    user.transactions.where(id: transaction_ids).update_all(
      needs_review: true,
      updated_at: Time.current
    )
  end

  def bulk_unflag(user, transaction_ids)
    user.transactions.where(id: transaction_ids).update_all(
      needs_review: false,
      updated_at: Time.current
    )

    # Mark all anomalies as resolved
    TransactionAnomaly.where(txn_id: transaction_ids, resolved: false)
                      .update_all(resolved: true, updated_at: Time.current)
  end

  def apply_rules_batch(user, transaction_ids)
    transactions = user.transactions.where(id: transaction_ids)
    RuleEngine.new(user).apply!(scope: transactions)
  end

  def detect_anomalies_batch(user, transaction_ids)
    transactions = user.transactions.where(id: transaction_ids)
    AnomalyDetector.new(user).scan_transactions(transactions)
  end
end