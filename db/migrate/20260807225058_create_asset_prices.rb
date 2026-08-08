class CreateAssetPrices < ActiveRecord::Migration[8.1]
  def change
    create_table :asset_prices do |t|
      # index: false because the composite index below also serves asset_id lookups
      t.references :asset, null: false, foreign_key: true, index: false
      t.decimal :price, precision: 18, scale: 6, null: false
      # The date the price is valid FOR, distinct from created_at
      t.datetime :as_of, null: false

      t.timestamps
    end

    # Serves "latest price on or before date X" — the snapshot job's hot query
    add_index :asset_prices, [ :asset_id, :as_of ], unique: true
  end
end
