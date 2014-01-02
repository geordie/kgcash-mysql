class TransactionImportFormat

	def buildTransaction
		raise "Not implemented"
	end

	def self.buildImportFormat( typeId )

		if typeId == "2"
			return TransactionImportFormatRbcVisa.new
		end

		return TransactionImportFormatVancity.new
	end
end
