class Account < ActiveRecord::Base
	include Comparable

	before_save :filter_import_type

	has_and_belongs_to_many :users

	has_many :credit_transactions, class_name: 'Transaction', foreign_key: 'acct_id_cr'
	has_many :debit_transactions, class_name: 'Transaction', foreign_key: 'acct_id_dr'

	SupportedFormats = ["Vancity","RBC Visa","Vancity Visa","Vancity Visa (New)","RBC Chequing"]
	AccountTypes = ["Expense","Income","Asset","Liability"]

	scope :importable, lambda {where("import_class IS NOT NULL")}

	def active_months
		last_tx_date = transactions[0].tx_date
		first_tx_date = transactions[transactions.count-1].tx_date
		months = (last_tx_date.year * 12 + last_tx_date.month) - (first_tx_date.year * 12 + first_tx_date.month)
	end

	def transactions_per_month
		(transactions.count / active_months).to_i
	end

	def <=> other
		return 0 if !name && !other.name
		return 1 if !name
		return -1 if !other.name
		name.downcase <=> other.name.downcase
	end

	private

	def filter_import_type
		if import_class == ""
			self.import_class = nil
		end
	end
end
