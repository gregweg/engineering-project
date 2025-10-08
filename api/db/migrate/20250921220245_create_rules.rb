class CreateRules < ActiveRecord::Migration[8.0]
  def change
    create_table :rules do |t|
      t.references :user, null: false, foreign_key: true
      t.string :field
      t.string :operator
      t.string :value
      t.string :action_type
      t.string :action_value
      t.integer :priority, default: 0
      t.boolean :enabled, default: true

      t.timestamps
    end
  end
end
