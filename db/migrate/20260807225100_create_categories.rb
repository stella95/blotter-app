class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      # index: false because the composite unique index below also serves user_id lookups
      t.references :user, null: false, foreign_key: true, index: false
      t.string :name, null: false
      t.string :color

      t.timestamps
    end

    add_index :categories, [ :user_id, :name ], unique: true
  end
end
