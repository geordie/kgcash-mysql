class Budget < ActiveRecord::Base
  belongs_to :user

  def sortedAccounts
  	return self.accounts.sort{|a,b| a.name.downcase <=> b.name.downcase }
  end
end
