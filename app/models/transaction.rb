require 'digest/md5'

class Transaction < ApplicationRecord

	has_one_attached :attachment

	validates_uniqueness_of :tx_hash, case_sensitive: false
	validates_presence_of :tx_date

	belongs_to :category
	belongs_to :user
	belongs_to :account, primary_key: 'id', foreign_key: 'acct_id_dr'

	before_save :ensure_hash

	before_validation :ensure_hash

	self.per_page = 50

	scope :in_year, lambda { |year|
		if !year.nil?
			where(
				'tx_date >= ? AND tx_date < ?',
				Date.new( year,1,1),
				Date.new( year + 1,1,1))
		end
	}

	scope :in_month_year, lambda { |month, year| where(
		"tx_date >= ? AND tx_date < ?",

			year.nil? ?
				Date.new(1900,1,1) :
				(month.nil? ?
					Date.new( year,1,1) :
					Date.new(year,month,1)),

			year.nil? ?
				Date.new(DateTime.now.year+1, 1, 1) :
				(!month.nil? && month < 12 ?
					Date.new(year, month+1, 1 ) :
					Date.new(year+1,1,1)))
	}

	scope :in_debit_acct, lambda { |acct_id| where("acct_id_dr = ?", acct_id) unless acct_id.nil? }
	scope :in_credit_acct, lambda { |acct_id| where("acct_id_cr = ?", acct_id) unless acct_id.nil? }

	scope :in_account, lambda { |account_id| where("acct_id_dr = ? or acct_id_cr = ?", account_id, account_id) unless account_id.nil? }

	scope :in_range, lambda { |min, max| where("((debit >= ? AND debit <= ?) OR debit IS NULL) OR (credit >= ? AND credit <= ?)",
					min == 0 ? -10000000 : min,
					max == 0 ? 10000000 : max,
					min == 0 ? -10000000 : min,
					max == 0 ? 10000000 : max)}

	scope :is_expense, lambda{ where("acct_id_cr in (select id from accounts where account_type = 'Liability' or account_type = 'Asset')") }
	scope :is_liability, lambda{ where("acct_id_dr in (select id from accounts where account_type = 'Asset')") }
	scope :is_asset, lambda{ where("acct_id_cr in (select id from accounts where account_type = 'Asset')") }
	scope :is_payment, lambda{ where("acct_id_dr in (select id from accounts where account_type = 'Liability')") }

	def self.income_by_category_OLD( user, year )
		return user.transactions
			.joins( "LEFT JOIN accounts ON accounts.id = transactions.acct_id_cr")
			.select("sum(credit) as credit, sum(debit) as debit, accounts.name, acct_id_cr")
			.where("(acct_id_dr in (select id from accounts where account_type = 'Asset' or account_type = 'Expense'))")
			.where("(acct_id_cr IS NULL or acct_id_cr in (select id from accounts where account_type = 'Income'))")
			.in_month_year(nil, year)
			.group("acct_id_cr")
	end

	def self.expenses_by_category_OLD( user, year )
		return user.transactions
			.joins( "LEFT JOIN accounts ON accounts.id = transactions.acct_id_dr")
			.select("sum(credit) as credit, sum(debit) as debit, accounts.name, acct_id_dr")
			.where("(acct_id_cr in (select id from accounts where account_type = 'Liability' or account_type = 'Asset'))")
			.where("(acct_id_dr IS NULL or acct_id_dr in (select id from accounts where account_type = 'Expense'))")
			.in_month_year(nil, year)
			.group("acct_id_dr")
	end

	def self.income_by_category( user, year=nil, month = nil )
		sTimeAggregate = year.nil? ? "year(tx_date)" : "month(tx_date)"

		sJoinsIncomeA = "LEFT JOIN accounts as accts_cr ON accts_cr.id = transactions.acct_id_cr"
		sJoinsIncomeB = "LEFT JOIN accounts as accts_dr ON accts_dr.id = transactions.acct_id_dr"

		sSelectIncome = sTimeAggregate + " as xCategory, " +\
		sTimeAggregate + " as xValue, "\
		"SUM(IF(accts_cr.account_type = 'Income', credit, debit*-1)) as 'income', "\
		"IF(accts_cr.account_type = 'Income', accts_cr.id, accts_dr.id) as acct_id, "\
		"IF(accts_cr.account_type = 'Income', accts_cr.name, accts_dr.name) as name"

		sGroupByIncome = sTimeAggregate + ", IF(accts_cr.account_type = 'Income', accts_cr.id, accts_dr.id),"\
		"IF(accts_cr.account_type = 'Income', accts_cr.name, accts_dr.name)"

		return user.transactions
			.joins( sJoinsIncomeA )
			.joins( sJoinsIncomeB )
			.select( sSelectIncome )
			.where("(acct_id_dr in (select id from accounts where account_type = 'Asset') "\
				"AND acct_id_cr in (select id from accounts where account_type = 'Income')) "\
					"OR "\
				"(acct_id_cr in (select id from accounts where account_type = 'Asset') "\
				"AND acct_id_dr in (select id from accounts where account_type = 'Income'))")
			.in_month_year(month, year)
			.group( sGroupByIncome )
			.order( sTimeAggregate )
	end

	def self.expenses_by_category(user,year=nil, month=nil)
		sTimeAggregate = year.nil? ? "year(tx_date)" : "month(tx_date)"
	
		sJoinsExpenseA = "LEFT JOIN accounts as accts_cr ON accts_cr.id = transactions.acct_id_cr"
		sJoinsExpenseB = "LEFT JOIN accounts as accts_dr ON accts_dr.id = transactions.acct_id_dr"

		sSelectExpense = sTimeAggregate + " as xCategory, " +\
		sTimeAggregate + " as xValue, "\
		"SUM(IF(accts_dr.account_type = 'Expense', debit, credit*-1)) as 'expenses', "\
		"IF(accts_dr.account_type = 'Expense', accts_dr.id, accts_cr.id) as acct_id, "\
		"IF(accts_dr.account_type = 'Expense', accts_dr.name, accts_cr.name) as name"
	
		sGroupByExpense = sTimeAggregate + ", IF(accts_dr.account_type = 'Expense', accts_dr.id, accts_cr.id),"\
		"IF(accts_dr.account_type = 'Expense', accts_dr.name, accts_cr.name)"

		return user.transactions
			.joins( sJoinsExpenseA )
			.joins( sJoinsExpenseB )
			.select(sSelectExpense)
			.where("(acct_id_dr in (select id from accounts where account_type = 'Asset' or account_type = 'Liability') "\
				"AND acct_id_cr in (select id from accounts where account_type = 'Expense')) "\
					"OR "\
				"(acct_id_cr in (select id from accounts where account_type = 'Asset' or account_type = 'Liability') "\
				"AND acct_id_dr in (select id from accounts where account_type = 'Expense'))")
			.in_month_year(month, year)
			.group( sGroupByExpense )
			.order( sTimeAggregate )
	end

	def self.income_by_account(user,year=nil, month=nil)
		sTimeAggregate = year.nil? ? "year(tx_date)" : "month(tx_date)"

		sJoinsIncomeAccounts = "LEFT JOIN accounts as accts_cr ON accts_cr.id = transactions.acct_id_cr"

		sSelectIncome = sTimeAggregate + " as quanta, " +\
		"accts_cr.name, " +\
		"accts_cr.id, " +\
		"SUM(IF(accts_cr.account_type = 'Income', credit, credit)) as 'credit'"

		sGroupIncomeAccount = sTimeAggregate + ", accts_cr.id"

		return user.transactions
			.joins( sJoinsIncomeAccounts )
			.select(sSelectIncome)
			.where("(acct_id_cr in (select id from accounts where account_type = 'Income'))")
			.in_month_year(month, year)
			.group( sGroupIncomeAccount )
			.order( sTimeAggregate )
	end

	def self.expenses_all_time(user, year=nil)
		sTimeAggregate = "year(tx_date)"

		sJoinsExpenseA = "LEFT JOIN accounts as accts_cr ON accts_cr.id = transactions.acct_id_cr"
		sJoinsExpenseB = "LEFT JOIN accounts as accts_dr ON accts_dr.id = transactions.acct_id_dr"

		sSelectExpense = "YEAR(tx_date) as year, "\
		"SUM(IF(accts_dr.account_type = 'Expense', debit, credit*-1)) as 'expenses' "

		sYearFilter = !year.nil? && year.is_a?(Integer) ? "year(tx_date) = " + year.to_s : ""

		return user.transactions
			.joins( sJoinsExpenseA )
			.joins( sJoinsExpenseB )
			.select(sSelectExpense)
			.where("(acct_id_dr in (select id from accounts where account_type = 'Asset' or account_type = 'Liability') "\
				"AND acct_id_cr in (select id from accounts where account_type = 'Expense')) "\
					"OR "\
				"(acct_id_cr in (select id from accounts where account_type = 'Asset' or account_type = 'Liability') "\
				"AND acct_id_dr in (select id from accounts where account_type = 'Expense')) "
				)
			.where( sYearFilter )
			.group( sTimeAggregate )
			.order( Arel.sql(sTimeAggregate) )
	end

	def self.revenues_all_time(user, year=nil)
		sTimeAggregate = "year(tx_date)"

		sJoinsIncomeA = "LEFT JOIN accounts as accts_cr ON accts_cr.id = transactions.acct_id_cr"
		sJoinsIncomeB = "LEFT JOIN accounts as accts_dr ON accts_dr.id = transactions.acct_id_dr"

		sSelectRevenue = "YEAR(tx_date) as year, "\
		"SUM(IF(accts_cr.account_type = 'Income', credit, debit*-1)) as 'revenue' "

		sYearFilter = !year.nil? && year.is_a?(Integer) ? "year(tx_date) = " + year.to_s : ""

		return user.transactions
			.joins( sJoinsIncomeA )
			.joins( sJoinsIncomeB )
			.select( sSelectRevenue )
			.where("(acct_id_dr in (select id from accounts where account_type = 'Asset') "\
				"AND acct_id_cr in (select id from accounts where account_type = 'Income')) "\
					"OR "\
				"(acct_id_cr in (select id from accounts where account_type = 'Asset') "\
				"AND acct_id_dr in (select id from accounts where account_type = 'Income'))")
			.where( sYearFilter )
			.group( sTimeAggregate )
			.order( Arel.sql( sTimeAggregate ) )
	end

	def self.uncategorized_expenses(user, year=nil)
		return user.transactions
			.select("year(tx_date) as year, count(*) as count, sum(credit) as uncategorized_expenses")
			.is_expense()
			.where("(acct_id_dr IS NULL)")
			.in_year(year)
			.group('year(tx_date)')
	end

	def self.uncategorized_revenue(user, year=nil)
		return user.transactions
			.select("year(tx_date) as year, count(*) as count, sum(debit) as uncategorized_revenue")
			.is_liability()
			.where("(acct_id_cr IS NULL)")
			.in_year(year)
			.group('year(tx_date)')
	end

	def ensure_hash
		if self.tx_hash.to_s == ''
			self.tx_hash = build_hash
		end
	end

	def build_hash
		return Digest::MD5.hexdigest( self.tx_date.to_s +
				(self.details or '')	+
				(self.debit.to_s or '') +
				(self.credit.to_s or '') )
	end

	def format_date
		@date = self.tx_date
		@date.strftime( '%d-%b-%Y')
	end

end
