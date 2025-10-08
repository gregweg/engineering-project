class AddIndexesToTransactionAnomalies < ActiveRecord::Migration[8.0]
  def change
    add_index :transaction_anomalies, [:txn_id, :flag_type, :resolved],
              name: "idx_anomalies_txn_flag_resolved"
    add_index :transaction_anomalies, :flag_type
  end
end