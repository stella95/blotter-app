class CreateCategoryEntryLineItems < ActiveRecord::Migration[8.1]
  def change
    create_table :category_entry_line_items do |t|
      # index: false because the composite unique index below also serves category_id lookups
      t.references :category, null: false, foreign_key: true, index: false
      # Kept indexed: needed for "which categories are on this line item"
      t.references :entry_line_item, null: false, foreign_key: true

      t.timestamps
    end

    add_index :category_entry_line_items, [ :category_id, :entry_line_item_id ],
              unique: true, name: "index_cat_eli_on_category_and_line_item"
  end
end
