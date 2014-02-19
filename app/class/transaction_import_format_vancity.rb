class TransactionImportFormatVancity

	# Sample Transactions in CSV Format
	# 000000659243-004-Z    -00001,10-Dec-2013,"DIRECT TRANSFER FROM         JUMPSTART HIGH INTEREST # 1                              ",,,2000.00,4439.38
	# 000000659243-004-Z    -00001,10-Dec-2013,"DIRECT BILL PAYMENT          ROYAL BANK VISA # 4290                                    Confirmation #0000000524234",,517.00,,3922.38

	$txTypeDict = {"DIRECT TRANSFER FROM" => "Transfer From",
		"DIRECT TRANSFER TO" => "Transfer To",
		"ATM CASH WITHDRAWAL" => "ATM Withdrawl",
		"DIRECT BILL PAYMENT" => "Bill",
		"PAYROLL DEPOSIT" =>  "Payroll",
		"POINT OF SALE PURCHASE" => "Point of Sale",
		"ACCOUNT SERVICE CHARGE" => "Service Charge",
		"DIRECT DEPOSIT" =>  "Deposit"
	}

	$txCatDict = { "STONGS" => 2,
		"CHEVRON" => 4,
		"DIALOG" => 24,
		"FORTISBC" => 3,
		"SHAW" => 3,
		"SHOPPERS" => 6,
		"BC HYDRO" => 3,
		"MSP RSBC" => 7,
		"ROYAL VANCOUVER YACHT" => 18,
		"VAN LAWN" => 9,
		"THE HEIGHTS" => 2,
		"CANADA SAFEW" => 2
	}

	def buildTransaction( csvline, account_id )
		fields = csvline.split(',')
		# field[0]: account
		# field[3]: cheque #
		# field[6]: balance

		# Get date
		sDate = fields[1]
		date = DateTime.strptime(sDate,'%d-%b-%Y')
		sDate = date.strftime( '%y-%m-%d' )

		# Get credit and debit amounts
		debit = fields[4].length > 0 ? fields[4] : "0"
		credit = (fields.length >= 6 && fields[5].length > 0) ? fields[5] : "0"

		# Parse the description into component parts
		@description = fields[2]

		# Strip quotes
		@description.delete!("\"")

		# Split on multiple spaces
		parts = @description.split(%r{[ ]{2,}})

		puts parts.to_s

		# Build a transaction type
		@type = parts[0]

		if $txTypeDict.has_key?( @type )
			@type = $txTypeDict[ @type ]
		else
			@type = @type.downcase
		end

		# Build transaction details
		if parts.length > 2
			parts[1] = parts[1] + " " + parts[2]
			@details = parts[1]
		else
			@details = parts[parts.length-1]
		end

		# Build transaction category
		cat = 27

		if !@details.nil?
			$txCatDict.each_key do |item|
				if !@details.index(item.to_s).nil?
					cat = $txCatDict[item].to_s
					break
				end
			end
		end

		# Build a transaction
		@transaction = Transaction.create(
			:tx_date => date,
			:posting_date => date,
			:user_id => 1,
			:debit => debit,
			:credit => credit,
			:account_id => account_id,
			:type => @type,
			:details => @details
			)

		@transaction.category_id = cat

		return @transaction
		
	end

	def skip_first_line
		return false
	end
end