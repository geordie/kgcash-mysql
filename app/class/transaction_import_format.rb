class TransactionImportFormat

	def buildTransaction(csvline, account_id, user_id)
		raise "Not implemented"
	end

	def skip_first_line
		raise "Not implemented"
	end

	def self.buildImportFormat( typeId )

		if typeId == "Vancity"
			return TransactionImportFormatVancity.new
		elsif typeId == "RBC Visa"
			return TransactionImportFormatRbcVisa.new
		elsif typeId == "Vancity Visa"
			return TransactionImportFormatVancityVisa.new
		elsif typeId == "Vancity Visa (New)"
			return TransactionImportFormatVancityVisaNew.new
		elsif typeId == "RBC Chequing"
			return TransactionImportFormatRbcChequing.new
		end

		return nil
		
	end
end
