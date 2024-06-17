class DropCategories < ActiveRecord::Migration[6.0]
  def up
    drop_table :categories
  end

  def down
    create_table :categories do |t|
      t.string :name
      t.text :description
      t.datetime :created_at
      t.datetime :updated_at
      t.integer :user_id
      t.string :cat_type

      t.timestamps
    end
  end
end