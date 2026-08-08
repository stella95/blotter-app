class CreateEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :entries do |t|
      # index: false because the composite index below also serves portfolio_id lookups
      t.references :portfolio, null: false, foreign_key: true, index: false
      # The date the money moved, distinct from created_at
      t.date :occurred_on, null: false
      t.string :description
      # Stable key from an imported file, used to avoid re-importing the same row
      t.string :external_ref

      t.timestamps
    end

    # Serves the monthly summary and CSV date-range filters
    add_index :entries, [ :portfolio_id, :occurred_on ]

    # Enforces import de-duplication rather than merely hoping for it
    add_index :entries, [ :portfolio_id, :external_ref ],
              unique: true, where: "external_ref IS NOT NULL"
  end
end
