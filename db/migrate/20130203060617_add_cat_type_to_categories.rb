class AddCatTypeToCategories < ActiveRecord::Migration[4.2]
  def change
    add_column :categories, :cat_type, :string
  end
end
