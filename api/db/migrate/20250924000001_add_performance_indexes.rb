class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Compound indexes for common query patterns
    add_index :transactions, [:user_id, :needs_review, :created_at], name: 'idx_txn_user_review_created'
    add_index :transactions, [:user_id, :amount, :date], name: 'idx_txn_user_amount_date'
    add_index :transactions, :description, using: :gin, opclass: :gin_trgm_ops, name: 'idx_txn_desc_gin'

    # Partial indexes for performance
    add_index :transactions, [:user_id, :category_id], where: 'category_id IS NULL', name: 'idx_txn_uncategorized'
    add_index :transaction_anomalies, [:txn_id, :flag_type], where: 'resolved = false', name: 'idx_anomalies_unresolved'

    # Covering indexes to avoid table lookups
    add_index :transactions, [:user_id, :fingerprint, :id, :amount, :date], name: 'idx_txn_covering'

    # Rules performance
    add_index :rules, [:user_id, :enabled, :priority], name: 'idx_rules_user_enabled_priority'
  end
end