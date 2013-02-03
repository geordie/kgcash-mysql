class AddCatTypeToCategories < ActiveRecord::Migration
  def change
    add_column :categories, :cat_type, :string
  end
end
