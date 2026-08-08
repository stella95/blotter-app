class CreateAssets < ActiveRecord::Migration[8.1]
  def change
    create_enum :asset_type, %w[stock etf bond cash crypto mutual_fund]

    create_table :assets do |t|
      t.string :symbol, null: false
      t.string :name, null: false
      t.enum :asset_type, enum_type: "asset_type", null: false
      t.string :currency, null: false, default: "EUR"
      # Soft-disable: delisted assets stay referenced by history but drop out of pickers
      t.boolean :active, null: false, default: true

      # Bond-specific, null for every other asset type
      t.date :maturity_date
      t.decimal :coupon_rate, precision: 8, scale: 4
      t.decimal :face_value, precision: 18, scale: 4

      t.string :isin

      t.timestamps
    end

    add_index :assets, :symbol, unique: true
    add_index :assets, :isin, unique: true, where: "isin IS NOT NULL"
  end
end
