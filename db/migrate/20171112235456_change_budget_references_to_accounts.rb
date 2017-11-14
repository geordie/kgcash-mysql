class ChangeBudgetReferencesToAccounts < ActiveRecord::Migration[4.2]
  def change
      remove_reference :budget_categories, :category
      add_reference :budget_categories, :account
  end
end
