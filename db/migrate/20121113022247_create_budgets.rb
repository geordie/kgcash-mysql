class CreateBudgets < ActiveRecord::Migration[4.2]
  def change
    create_table :budgets do |t|
      t.string :name
      t.text :description
      t.references :user

      t.timestamps
    end
    add_index :budgets, :user_id
  end
end
