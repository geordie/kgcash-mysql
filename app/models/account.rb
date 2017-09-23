class Account < ActiveRecord::Base
	has_many :transactions
	has_and_belongs_to_many :users

	SupportedFormats = ["Vancity","RBC Visa","Vancity Visa"]

	scope :importable, lambda {where("import_class IS NOT NULL")}

	def active_months
		last_tx_date = transactions[0].tx_date
		first_tx_date = transactions[transactions.count-1].tx_date
		months = (last_tx_date.year * 12 + last_tx_date.month) - (first_tx_date.year * 12 + first_tx_date.month)
	end

	def transactions_per_month
		(transactions.count / active_months).to_i
	end

	def self.expense_accounts
	 	self.where("account_type = ? or account_type = ? or account_type = ?", "Expense", "Liability", "Asset" ).order(:name)
 	end

	def self.income_accounts
	 	self.where("account_type = ? or account_type = ?", "Income", "Asset").order(:name)
 	end

end
