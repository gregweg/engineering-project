class RemoveRedundantIndexes < ActiveRecord::Migration[8.0]
  def up
    # Remove duplicate GIN trigram index on description
    # Keep idx_txn_desc_gin, remove idx_transactions_description_search
    remove_index :transactions, name: "idx_transactions_description_search", if_exists: true

    # Remove duplicate partial index for uncategorized transactions
    # Keep idx_txn_uncategorized, remove idx_transactions_uncategorized
    remove_index :transactions, name: "idx_transactions_uncategorized", if_exists: true
  end

  def down
    # Recreate the removed indexes if rolling back
    add_index :transactions, :description,
      name: "idx_transactions_description_search",
      using: :gin,
      opclass: :gin_trgm_ops

    add_index :transactions, [:user_id, :category_id],
      name: "idx_transactions_uncategorized",
      where: "category_id IS NULL"
  end
end
