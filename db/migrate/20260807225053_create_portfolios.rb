class CreatePortfolios < ActiveRecord::Migration[8.1]
  def change
    create_table :portfolios do |t|
      # index: false because the composite unique index below also serves user_id lookups
      t.references :user, null: false, foreign_key: true, index: false
      t.string :name, null: false
      t.string :currency, null: false, default: "EUR"
      t.datetime :archived_at

      t.timestamps
    end

    add_index :portfolios, [ :user_id, :name ], unique: true
  end
end
