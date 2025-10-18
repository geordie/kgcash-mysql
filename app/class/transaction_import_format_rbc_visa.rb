require 'csv'

class TransactionImportFormatRbcVisa

	# Sample Transactions in CSV Format
	# Account Type,Account Number,Transaction Date,Cheque Number,Description 1,Description 2,CAD$,USD$
	# Visa,4.51224E+15,11/26/2013,,CAR2GO 855-454-1002 BC,,-$14.47,

	# To regex a PDF statement
	# replace \n[0-9]{23}\n
	# with ,
	# replace \n\$
	# with ,$
	# replace ^[A-Z]{3} [0-9]{2}
	# with Visa,
	# replace , MAY ([0-9]{2})
	# with ,, 05/\1/2014
	# replace , JUN ([0-9]{2})
	# with ,, 06/\1/2014
	# replace , JUL ([0-9]{2})
	# ,, 07/\1/2014
	# replace /2014
	# with /2014,,

	def buildTransaction( csvline, account_id, user_id )
		fields = CSV.parse(csvline)[0]

		# Get date
		sDate = fields[2]
		if sDate.nil? || sDate.empty?
			return nil
		end

		date = DateTime.strptime(sDate,'%m/%d/%Y')
		sDate = date.strftime( '%y-%m-%d' )

		# Get credit and debit amounts
		rawAmount = fields[6].delete("$\", \t\r\n")
		@amount = BigDecimal( rawAmount )

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
			:user_id => user_id,
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
