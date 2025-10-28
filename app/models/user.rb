class User < ActiveRecord::Base
	authenticates_with_sorcery!
	#attr_accessible :username, :email, :password, :password_confirmation
	#:role

	validates_uniqueness_of :email, case_sensitive: false
	validates_length_of :password, :minimum => 5, :message => "password must be at least 5 characters long", :if => :password
	validates_confirmation_of :password, :message => "should match confirmation", :if => :password

	has_many :categories
	has_many :transactions
	has_and_belongs_to_many :documents
	has_many :accounts, dependent: :destroy
	has_many :notes

	after_create :create_suspense_accounts

	def sortedCategories
		return categories.to_a.sort!{|a,b| a.name.downcase <=> b.name.downcase }
	end

	def sortedAccounts
		return accounts.to_a.sort
	end

	def account_selector(importonly = false)

		#Build an array of pairs as expected by a form dropdown
		results = Array.new

		accounts.each do |acct|
			if importonly && acct.import_class.nil?
				next
			end
			if acct.name.nil?
				next
			end
			rec = Array.new
			rec.push acct.name
			rec.push acct.id
			results.push rec
		end
		return results.sort
	end

	def roles
		result = :user
		if !self.role.nil?
			result = self.role.to_sym
		end
		return result
	end

	# Helper method to get user's uncategorized expense account
	def uncategorized_expense_account
		accounts.find_by(name: 'Uncategorized Expenses')
	end

	# Helper method to get user's uncategorized income account
	def uncategorized_income_account
		accounts.find_by(name: 'Uncategorized Income')
	end

	private

	def create_suspense_accounts
		# Create Uncategorized Expenses account
		accounts.create!(
			name: 'Uncategorized Expenses',
			account_type: 'Expense',
			description: 'Temporary holding account for imported expenses awaiting categorization'
		)

		# Create Uncategorized Income account
		accounts.create!(
			name: 'Uncategorized Income',
			account_type: 'Income',
			description: 'Temporary holding account for imported income awaiting categorization'
		)
	end

end
