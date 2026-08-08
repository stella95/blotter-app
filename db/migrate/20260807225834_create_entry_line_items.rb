class CreateEntryLineItems < ActiveRecord::Migration[8.1]
  def change
    create_enum :entry_action,
                 %w[buy sell dividend interest deposit withdrawal fee transfer_in transfer_out]

    create_table :entry_line_items do |t|
      t.references :entry, null: false, foreign_key: true
      t.references :asset, null: false, foreign_key: true

      t.enum :action, enum_type: "entry_action", null: false

      # 8 decimal places so fractional crypto survives; 0 is correct for pure-cash actions
      t.decimal :quantity, precision: 18, scale: 8, null: false, default: 0

      # Null on actions where it is meaningless (a fee has no per-unit price)
      t.decimal :price_per_unit, precision: 18, scale: 6

      # Signed, authoritative cash effect. NOT derived from quantity * price_per_unit,
      # because fees and transfers do not have that shape.
      t.decimal :amount, precision: 18, scale: 4, null: false

      t.text :notes

      t.timestamps
    end
  end
end
