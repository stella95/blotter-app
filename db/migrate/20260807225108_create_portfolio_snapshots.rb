class CreatePortfolioSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :portfolio_snapshots do |t|
      # index: false because the composite unique index below also serves portfolio_id lookups
      t.references :portfolio, null: false, foreign_key: true, index: false
      t.date :captured_on, null: false

      # One row per portfolio PER CURRENCY per day. With no FX conversion in v1,
      # a mixed EUR/USD portfolio has no single correct total.
      t.string :currency, null: false

      t.decimal :total_market_value, precision: 18, scale: 4, null: false, default: 0
      t.decimal :total_cost_basis, precision: 18, scale: 4, null: false, default: 0
      t.decimal :net_cash_flow_to_date, precision: 18, scale: 4, null: false, default: 0

      # How many held assets had no price at all, so the UI can say the line is incomplete
      t.integer :unpriced_assets_count, null: false, default: 0

      t.timestamps
    end

    add_index :portfolio_snapshots, [ :portfolio_id, :currency, :captured_on ], unique: true
  end
end
