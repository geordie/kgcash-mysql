class BudgetCategory < ActiveRecord::Base
  belongs_to :budget
  belongs_to :category

  def isDebit
  	if self.category.is_nil?
  		return true
  	elsif self.category.cat_type == "Income"
  		return false
  	end
  	return true
  end
end
