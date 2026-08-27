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

ActiveRecord::Schema[8.1].define(version: 2026_08_27_090000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "asset_type", ["stock", "etf", "bond", "cash", "crypto", "mutual_fund"]
  create_enum "entry_action", ["buy", "sell", "dividend", "interest", "deposit", "withdrawal", "fee", "transfer_in", "transfer_out"]

  create_table "asset_prices", force: :cascade do |t|
    t.datetime "as_of", null: false
    t.bigint "asset_id", null: false
    t.datetime "created_at", null: false
    t.decimal "price", precision: 18, scale: 6, null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id", "as_of"], name: "index_asset_prices_on_asset_id_and_as_of", unique: true
  end

  create_table "assets", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.enum "asset_type", null: false, enum_type: "asset_type"
    t.decimal "coupon_rate", precision: 8, scale: 4
    t.datetime "created_at", null: false
    t.string "currency", default: "EUR", null: false
    t.decimal "face_value", precision: 18, scale: 4
    t.string "isin"
    t.date "maturity_date"
    t.string "name", null: false
    t.string "symbol", null: false
    t.datetime "updated_at", null: false
    t.index ["isin"], name: "index_assets_on_isin", unique: true, where: "(isin IS NOT NULL)"
    t.index ["symbol"], name: "index_assets_on_symbol", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.string "color"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "name"], name: "index_categories_on_user_id_and_name", unique: true
  end

  create_table "category_entry_line_items", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.bigint "entry_line_item_id", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id", "entry_line_item_id"], name: "index_cat_eli_on_category_and_line_item", unique: true
    t.index ["entry_line_item_id"], name: "index_category_entry_line_items_on_entry_line_item_id"
  end

  create_table "entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "external_ref"
    t.date "occurred_on", null: false
    t.bigint "portfolio_id", null: false
    t.datetime "updated_at", null: false
    t.index ["portfolio_id", "external_ref"], name: "index_entries_on_portfolio_id_and_external_ref", unique: true, where: "(external_ref IS NOT NULL)"
    t.index ["portfolio_id", "occurred_on"], name: "index_entries_on_portfolio_id_and_occurred_on"
  end

  create_table "entry_line_items", force: :cascade do |t|
    t.enum "action", null: false, enum_type: "entry_action"
    t.decimal "amount", precision: 18, scale: 4, null: false
    t.bigint "asset_id", null: false
    t.datetime "created_at", null: false
    t.bigint "entry_id", null: false
    t.text "notes"
    t.decimal "price_per_unit", precision: 18, scale: 6
    t.decimal "quantity", precision: 18, scale: 8, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "index_entry_line_items_on_asset_id"
    t.index ["entry_id"], name: "index_entry_line_items_on_entry_id"
  end

  create_table "portfolio_snapshots", force: :cascade do |t|
    t.date "captured_on", null: false
    t.datetime "created_at", null: false
    t.string "currency", null: false
    t.decimal "net_cash_flow_to_date", precision: 18, scale: 4, default: "0.0", null: false
    t.bigint "portfolio_id", null: false
    t.decimal "total_cost_basis", precision: 18, scale: 4, default: "0.0", null: false
    t.decimal "total_market_value", precision: 18, scale: 4, default: "0.0", null: false
    t.integer "unpriced_assets_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["portfolio_id", "currency", "captured_on"], name: "idx_on_portfolio_id_currency_captured_on_893b290cef", unique: true
  end

  create_table "portfolios", force: :cascade do |t|
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "name"], name: "index_portfolios_on_user_id_and_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "locked_at"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.string "time_zone", default: "UTC", null: false
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "asset_prices", "assets"
  add_foreign_key "categories", "users"
  add_foreign_key "category_entry_line_items", "categories"
  add_foreign_key "category_entry_line_items", "entry_line_items"
  add_foreign_key "entries", "portfolios"
  add_foreign_key "entry_line_items", "assets"
  add_foreign_key "entry_line_items", "entries"
  add_foreign_key "portfolio_snapshots", "portfolios"
  add_foreign_key "portfolios", "users"
end
