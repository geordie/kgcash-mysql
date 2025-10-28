class Account < ActiveRecord::Base
	include Comparable

	before_save :filter_import_type

	belongs_to :user

	has_many :credit_transactions, class_name: 'Transaction', foreign_key: 'acct_id_cr'
	has_many :debit_transactions, class_name: 'Transaction', foreign_key: 'acct_id_dr'

	SupportedFormats = ["Vancity","RBC Visa","Vancity Visa","Vancity Visa (New)","RBC Chequing"]
	AccountTypes = ["Expense","Income","Asset","Liability"]

	scope :importable, lambda {where("import_class IS NOT NULL")}
	scope :expense, lambda {where("account_type = 'Expense'")}
	scope :income, lambda {where("account_type = 'Income'")}
	scope :asset, lambda {where("account_type = 'Asset'")}
	scope :liability, lambda {where("account_type = 'Liability'")}

	def active_months
		last_tx_date = transactions[0].tx_date
		first_tx_date = transactions[transactions.count-1].tx_date
		months = (last_tx_date.year * 12 + last_tx_date.month) - (first_tx_date.year * 12 + first_tx_date.month)
	end

	def credits(year=nil)
		if year.nil?
			year = Time.now.year
		end
		credit_transactions.where("year(tx_date) = ?", year).sum(:credit)
	end

	def debits(year=nil)
		if year.nil?
			year = Time.now.year
		end
		debit_transactions.where("year(tx_date) = ?", year).sum(:debit)
	end

	def debits_monthly(year=nil)
		if year.nil?
			year = Time.now.year
		end
		debit_transactions.where("year(tx_date) = ?", year).group('month(tx_date)').sum(:debit)
	end

	def credits_monthly(year=nil)
		if year.nil?
			year = Time.now.year
		end
		credit_transactions.where("year(tx_date) = ?", year).group('month(tx_date)').sum(:credit)
	end

	def debits_yearly(max_years=10)
		debit_transactions
			.where('year(tx_date) > ? ', Date.today.year - max_years)
			.group('year(tx_date)').sum(:debit)
	end

	def credits_yearly(max_years=10)
		credit_transactions
			.where('year(tx_date) > ? ', Date.today.year - max_years)
			.group('year(tx_date)').sum(:credit)
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
