require 'csv'

class TransactionImportFormatRbcChequing

	# Sample Transactions in CSV Format
	# Account Type,Account Number,Transaction Date,Cheque Number,Description 1,Description 2,CAD$,USD$
	# Visa,4.51224E+15,11/26/2013,,CAR2GO 855-454-1002 BC,,-$14.47,

	def buildTransaction( csvline, account_id )
		fields = CSV.parse(csvline)[0]

		# Get date
		sDate = fields[2]
		if sDate.nil? || sDate.empty?
			return nil
		end

		date = DateTime.strptime(sDate,'%m/%d/%Y')
		sDate = date.strftime( '%y-%m-%d' )

		# Get credit and debit amounts
		@amount = BigDecimal.new( fields[6].delete("$\",") )

		# Get the description
		details = fields[4]
		if !fields[5].nil? && fields[5].length > 0
			details += " " + fields[5]
 		end

		debit = @amount > 0 ? @amount : nil
		credit = @amount <= 0 ? @amount * -1 : nil

		# Build a transaction
		@transaction = Transaction.create(
			:tx_date => date,
			:posting_date => date,
			:user_id => 1,
			:details => details,
			:debit => debit,
			:acct_id_dr => (debit.nil? ? nil : account_id),
			:credit => credit,
			:acct_id_cr => (credit.nil? ? nil : account_id)
		)

		return @transaction
	end

	def skip_first_line
		return true
	end
end
