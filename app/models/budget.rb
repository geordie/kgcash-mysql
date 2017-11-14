class Budget < ActiveRecord::Base
  belongs_to :user
  has_many :budget_categories, :dependent => :delete_all
  has_many :accounts, :through => :budget_categories

  def sortedAccounts
  	return self.accounts.sort{|a,b| a.name.downcase <=> b.name.downcase }
  end
end
