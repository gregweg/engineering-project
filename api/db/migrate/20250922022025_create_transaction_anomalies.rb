class CreateTransactionAnomalies < ActiveRecord::Migration[8.0]
  def change
    create_table :transaction_anomalies do |t|
      t.references :txn, null: false, foreign_key: { to_table: :transactions }
      t.string  :flag_type
      t.jsonb   :details,  default: {}
      t.boolean :resolved, default: false, null: false

      t.timestamps
    end

    add_index :transaction_anomalies, [:txn_id, :flag_type]
  end
end