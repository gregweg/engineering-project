class RegenerateTransactionFingerprints < ActiveRecord::Migration[8.0]
  def up
    # Temporarily drop the unique index to allow fingerprint regeneration
    remove_index :transactions, name: "index_transactions_on_user_id_and_fingerprint", if_exists: true

    # Regenerate fingerprints using SHA256 (via TxnUtils.fingerprint)
    # Process in batches to avoid memory issues with large datasets
    say_with_time "Regenerating transaction fingerprints with SHA256" do
      Transaction.find_each(batch_size: 1000) do |txn|
        new_fingerprint = TxnUtils.fingerprint(
          user_id: txn.user_id,
          date: txn.date,
          amount: txn.amount,
          description: txn.description
        )
        txn.update_column(:fingerprint, new_fingerprint)
      end
    end

    # Recreate the unique index
    add_index :transactions, [:user_id, :fingerprint], unique: true, name: "index_transactions_on_user_id_and_fingerprint"
  end

  def down
    # Cannot reverse fingerprint algorithm change
    raise ActiveRecord::IrreversibleMigration, "Cannot revert SHA256 fingerprints back to MD5"
  end
end
