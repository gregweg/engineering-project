class FixNullFlagTypes < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      UPDATE transaction_anomalies
      SET flag_type = 'manual'
      WHERE flag_type IS NULL;
    SQL

    change_column_default :transaction_anomalies, :flag_type, from: nil, to: "manual"
    change_column_null :transaction_anomalies, :flag_type, false
  end

  def down
    change_column_null :transaction_anomalies, :flag_type, true
    change_column_default :transaction_anomalies, :flag_type, from: "manual", to: nil
  end
end
