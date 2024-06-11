class DropBudgetCategories < ActiveRecord::Migration[4.2]
  def up
    drop_table :budget_categories
  end

  def down
    create_table :budget_categories do |t|
      t.decimal :amount
      t.string :period
      t.references :budget
      t.references :category

      t.timestamps
    end
    add_index :budget_categories, :budget_id
    add_index :budget_categories, :category_id
  end
end