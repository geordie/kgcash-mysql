class CategorySummary
	attr_reader :values

	def initialize( array, valueKey, year )

		days = DateMath.days_past_in_year( year )
		months = DateMath.months_past_in_year( year )
		@summaryBuilder = Hash.new()
		catTotal = 0

		for item in array do

			if !@summaryBuilder.key?(item.acct_id)
				@summaryBuilder[item.acct_id] = Array.new(13){0}
				@summaryBuilder[item.acct_id][0] = [item.name, item.acct_id, 0, 0]
			end
			amountMonth = item[valueKey].nil? ? 0 : item[valueKey]
			@summaryBuilder[item.acct_id][item.xCategory] = amountMonth
			@summaryBuilder[item.acct_id][0][2] += amountMonth
		end

		for item in @summaryBuilder.values do
			item[0][3] = item[0][2]/months
			item[0][4] = item[0][2]/days
		end
		@values = @summaryBuilder.values.sort{ |a,b| b[0][2] <=> a[0][2] }

	end

end