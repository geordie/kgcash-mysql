require 'csv'

class TransactionImportFormatVancityVisaNew

	# Sample Transactions in CSV Format
	# Name, Acct Num, Transaction Date, Posting Date, Merchant, Currency, Credit, Debit
	# GEORDIE A HENDERSON,4789 01•• •••• 6773,2018-04-30,2018-04-30T00:00,AUTO PAYMENT DEDUCTION,CAD,,10.00
	# GEORDIE A HENDERSON,4789 01•• •••• 6773,2018-04-12,2018-04-13T00:00,HEROKU MAR-16920959 HEROKU.COM CA,CAD,12.86,

	def buildTransaction( csvline, account_id, user_id )
		
		# Get rid of ", pair within lines
		csvline.gsub!(/\",/, "")
		fields = CSV.parse(csvline)[0]

		# Get date
		sDate = fields[2]
		date = DateTime.strptime(sDate,'%Y-%m-%d')

		# Get credit and debit amounts
		credit = 0
		debit = 0

		# Credit
		if !fields[6].nil? && !fields[6].empty?
			credit = BigDecimal( fields[6].delete("$\",()") )
		end

		# Debit
		if !fields[7].nil? && !fields[7].empty?
			debit = BigDecimal( fields[7].delete("$\",()") )
		end

		# Get the description
		details = fields[4]
		
		# Build a transaction
		@transaction = Transaction.create(
			:tx_date => date,
			:posting_date => date,
			:user_id => user_id,
			:details => details,
			:debit => debit,
			:acct_id_dr => (debit > 0 ? account_id : nil),
			:credit => credit,
			:acct_id_cr => (credit > 0 ? account_id : nil),
		)

		return @transaction

	end

	def skip_first_line
		return false
	end
end
