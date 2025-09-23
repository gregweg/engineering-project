# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_09_23_040911) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "categories", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name"
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "import_batches", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "filename"
    t.string "status"
    t.integer "total_rows"
    t.integer "processed_rows"
    t.jsonb "error_messages"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_import_batches_on_user_id"
  end

  create_table "rules", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "field"
    t.string "operator"
    t.string "value"
    t.string "action_type"
    t.string "action_value"
    t.integer "priority", default: 0
    t.boolean "enabled", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_rules_on_user_id"
  end

  create_table "transaction_anomalies", force: :cascade do |t|
    t.bigint "txn_id", null: false
    t.string "flag_type", default: "manual", null: false
    t.jsonb "details", default: {}
    t.boolean "resolved", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["flag_type"], name: "index_transaction_anomalies_on_flag_type"
    t.index ["txn_id", "flag_type", "resolved"], name: "idx_anomalies_txn_flag_resolved"
    t.index ["txn_id", "flag_type"], name: "index_transaction_anomalies_on_txn_id_and_flag_type"
    t.index ["txn_id"], name: "index_transaction_anomalies_on_txn_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "category_id"
    t.date "date"
    t.decimal "amount", precision: 15, scale: 2
    t.text "description"
    t.jsonb "metadata", default: {}
    t.string "fingerprint", null: false
    t.boolean "needs_review", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["amount"], name: "index_transactions_on_amount"
    t.index ["category_id"], name: "index_transactions_on_category_id"
    t.index ["user_id", "category_id"], name: "index_transactions_on_user_id_and_category_id"
    t.index ["user_id", "date"], name: "index_transactions_on_user_id_and_date"
    t.index ["user_id", "fingerprint"], name: "index_transactions_on_user_id_and_fingerprint", unique: true
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email"
  end

  add_foreign_key "categories", "users"
  add_foreign_key "import_batches", "users"
  add_foreign_key "rules", "users"
  add_foreign_key "transaction_anomalies", "transactions", column: "txn_id"
  add_foreign_key "transactions", "categories"
  add_foreign_key "transactions", "users"
end
