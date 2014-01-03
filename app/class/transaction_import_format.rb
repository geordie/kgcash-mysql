class TransactionImportFormat

	def buildTransaction
		raise "Not implemented"
	end

	def skip_first_line
		raise "Not implemented"
	end

	def self.buildImportFormat( typeId )

		if typeId == "2"
			return TransactionImportFormatRbcVisa.new
		elsif typeId == "3"
			return TransactionImportFormatVancityVisa.new
		end

		return TransactionImportFormatVancity.new
	end
end
