class CreateImportBatches < ActiveRecord::Migration[8.0]
  def change
    create_table :import_batches do |t|
      t.references :user, null: false, foreign_key: true
      t.string :filename
      t.string :status
      t.integer :total_rows
      t.integer :processed_rows
      t.jsonb :error_messages

      t.timestamps
    end
  end
end
