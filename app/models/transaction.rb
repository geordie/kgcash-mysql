require 'digest/md5'

class Transaction < ActiveRecord::Base

	attr_accessor :budget

	validates_uniqueness_of :tx_hash
	validates_presence_of :tx_date

	belongs_to :category
	belongs_to :user
	belongs_to :account, primary_key: 'id', foreign_key: 'acct_id_dr'

	before_save :ensure_hash

	before_validation :ensure_hash

	self.per_page = 50

	scope :in_year, lambda { |year| where('tx_date >= ? AND tx_date < ?', Date.new( year,1,1) , Date.new( year + 1,1,1)) }

	scope :in_month_year, lambda { |month, year| where( 'tx_date >= ? AND tx_date < ?',
					month.nil? ? Date.new( year,1,1) : Date.new(year,month,1),
					!month.nil? && month < 12 ? Date.new(year, month+1, 1 ) : Date.new(year+1,1,1) )
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
			.in_year(year)
			.group("acct_id_cr")
	end

	def self.income_by_category( user, year )
		sTimeAggregate = "month(tx_date)"

		sJoinsIncomeA = "LEFT JOIN accounts as accts_cr ON accts_cr.id = transactions.acct_id_cr"
		sJoinsIncomeB = "LEFT JOIN accounts as accts_dr ON accts_dr.id = transactions.acct_id_dr"

		sSelectIncome = sTimeAggregate + " as quantum, "\
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
			.in_year(year)
			.group( sGroupByIncome )
			.order( sTimeAggregate )
	end

	def self.expenses_by_category(user,year)
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

	def attributes
		super.merge('budget' => self.budget)
	end

end
