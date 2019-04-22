class TransactionImportFormat

	def buildTransaction
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
		end

		return nil
		
	end
end
