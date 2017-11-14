class BudgetCategory < ActiveRecord::Base
  belongs_to :budget
  belongs_to :account

  def isDebit
  	if self.account.nil?
  		return true
  	elsif self.account.account_type == "Income"
  		return false
  	end
  	return true
  end
end
