class CategorySummary
	attr_reader :values

	def initialize( array, valueKey, year )

		days = DateMath.days_past_in_year( year )
		months = DateMath.months_past_in_year( year )
		month_totals = Array.new(12){0}
		grand_total = 0
		@summaryBuilder = Hash.new()

		for item in array do

			if !@summaryBuilder.key?(item.acct_id)
				@summaryBuilder[item.acct_id] = Array.new(1){0}
				@summaryBuilder[item.acct_id][0] = {
					"cat_name" => item.name,
					"cat_id" => item.acct_id,
					"total" => 0,
					"monthly" => 0,
					"daily" => 0,
					"months" => Array.new(12){0}
				}
			end
			idx = [item.xCategory-1, 0].max
			amountMonth = item[valueKey].nil? ? 0 : item[valueKey]
			@summaryBuilder[item.acct_id][0]["months"][idx] = amountMonth
			@summaryBuilder[item.acct_id][0]["total"] += amountMonth

			month_totals[idx] += amountMonth
			grand_total += amountMonth
		end

		for item in @summaryBuilder.values do
			item[0]["monthly"] = item[0]["total"]/months
			item[0]["daily"] = item[0]["total"]/days
		end
		@summaryBuilder = @summaryBuilder.values.sort{ |a,b| b[0]["total"] <=> a[0]["total"] }

		monthly_totals = {
			"cat_name" => "Totals",
			"cat_id" => 0,
			"total" => grand_total,
			"monthly" => grand_total/months,
			"daily" => grand_total/days,
			"months" => month_totals
		}
		@summaryBuilder.append([monthly_totals])

		@values = @summaryBuilder

		return @values
	end

end