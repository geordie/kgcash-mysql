class CategorySummary
	attr_reader :values

	def initialize( array, valueKey )
		
		@summaryBuilder = Hash.new()

		for item in array do

			if !@summaryBuilder.key?(item.acct_id)
				@summaryBuilder[item.acct_id] = Array.new(13){0}
				@summaryBuilder[item.acct_id][0] = [item.name, :id]
			end

			@summaryBuilder[item.acct_id][item.quantum] = item[valueKey]
		end

		@values = @summaryBuilder.values
	end

end