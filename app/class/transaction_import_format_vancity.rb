class TransactionImportFormatVancity < TransactionImportFormat

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

		sDate = fields[1]
		date = DateTime.strptime(sDate,'%d-%b-%Y')
		sDate = date.strftime( '%y-%m-%d' )

		descParts = parseDescription(fields[2])

		if descParts.length == 1
			type = descParts[0]
		elsif descParts.length > 0
			desc = descParts[descParts.length-1]
		end

		debit = fields[4].length > 0 ? fields[4] : "0"
		credit = (fields.length >= 6 && fields[5].length > 0) ? fields[5] : "0"

		cat = 27

		if !desc.nil?
			$txCatDict.each_key do |item|
				if !desc.index(item.to_s).nil?
					cat = $txCatDict[item].to_s
					break
				end
			end
		end

		@transaction = Transaction.create(
			:tx_date => date,
			:posting_date => date,
			:user_id => 1,
			:debit => debit,
			:credit => credit,
			:tx_type => type,
			:details => desc,
			:category_id => cat,
			:account_id => account_id
			)
	end

	def parseDescription( desc )

		parts = desc.split(" " * 7)
		type = parts[0].strip

		if $txTypeDict.has_key?( type )
			parts[0] = txTypeDict[ type ]
		else
			parts[0] = type.downcase
		end

		parts[0] = parts[0].gsub( "\"", "")
		parts.delete("")

		if parts.length > 2
			parts[1] = parts[1].strip + " " + parts[2].strip
			parts[1] = parts[1].gsub( "\"", "").strip
		end

		parts[0,2]
	end
end