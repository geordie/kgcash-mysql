require 'csv'

class TransactionImportFormatVancityVisa

	# Sample Transactions in CSV Format
	# Transaction Date, Posting Date, Billing Amount, Merchant, Merchant City , Merchant State , Merchant Zip , Reference Number , Debit/Credit Flag , SICMCC Code
	# 02/01/2013,03/01/2013,$178.08,"RESORT RESERVATIONS WHIST","BURNABY",BC,0000000000, "74064493002820133211288",D,7299
	# 02/01/2013,04/01/2013,$26.52,"PECKINPAH RESTAURANTS LTD","VANCOUVER",BC,0000000000, "74064493003820104911717",D,5812

	def buildTransaction( csvline, account_id )
		csvline.gsub!(/,[ ]{1,}\"/, ",\"")
		fields = CSV.parse(csvline)[0]

		# Get date
		sDate = fields[0]
		date = DateTime.strptime(sDate,'%d/%m/%Y')
		sDate = date.strftime( '%y-%m-%d' )

		# Get credit and debit amounts
		@flag = fields[8]
		@amount = BigDecimal( fields[2].delete("$\",()") )

		# Get the description
		details = fields[3]
		if !fields[4].nil? && fields[4].length > 0
			details += " " + fields[4]
 		end

 		if !fields[5].nil? && fields[5].length > 0
			details += " " + fields[5]
 		end

		# Build a transaction
		@transaction = Transaction.create(
			:tx_date => date,
			:posting_date => date,
			:user_id => 1,
			:details => details,
			:debit => (@flag == "C" ? @amount : nil),
			:acct_id_dr => (@flag == "C" ? account_id : nil),
			:credit => (@flag == "D" ? @amount : nil),
			:acct_id_cr => (@flag == "D" ? account_id : nil),
		)

		return @transaction

	end

	def skip_first_line
		return true
	end
end
