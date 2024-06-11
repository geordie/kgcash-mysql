class DropBudgets < ActiveRecord::Migration[4.2]
  def up
    drop_table :budgets
  end

  def down
    create_table :budgets do |t|
      t.string :name
      t.text :description
      t.references :user

      t.timestamps
    end
    add_index :budgets, :user_id
  end
end