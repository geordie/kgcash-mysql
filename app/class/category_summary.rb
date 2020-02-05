class CategorySummary
	attr_reader :values

	def initialize( array, valueKey )
		
		@summaryBuilder = Hash.new()
		catTotal = 0

		for item in array do

			if !@summaryBuilder.key?(item.acct_id)
				@summaryBuilder[item.acct_id] = Array.new(13){0}
				@summaryBuilder[item.acct_id][0] = [item.name, item.acct_id, 0]
			end
			amountMonth = item[valueKey].nil? ? 0 : item[valueKey]
			@summaryBuilder[item.acct_id][item.quantum] = amountMonth
			@summaryBuilder[item.acct_id][0][2] += amountMonth
		end
		@values = @summaryBuilder.values
	end

end