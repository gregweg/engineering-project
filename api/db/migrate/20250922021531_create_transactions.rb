class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.references :user,     null: false, foreign_key: true
      t.references :category, null: true,  foreign_key: true  # make null: true for now
      t.date    :date,        null: false
      t.decimal :amount,      null: false, precision: 15, scale: 2
      t.text    :description
      t.jsonb   :metadata,    default: {}
      t.string  :fingerprint, null: false
      t.boolean :needs_review, default: false, null: false

      t.timestamps
    end

    add_index :transactions, [:user_id, :date]
    add_index :transactions, [:user_id, :category_id]
    add_index :transactions, :amount
    add_index :transactions, [:user_id, :fingerprint], unique: true
  end
end