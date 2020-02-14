module DateMath
	def self.last_month( month, year )
		if month.nil? || year.nil? then
			return month, year
		end
		lastMonthYear = month <= 1 ? year - 1 : year
		lastMonth = month <= 1 ? 12 : month - 1
		return lastMonth, lastMonthYear
	end

	def self.next_month( month, year )
		if month.nil? || year.nil? then
			return month, year
		end
		nextMonthYear = month >= 12 ? year + 1 : year
		nextMonth = month >= 12 ? 1 : month + 1
		return nextMonth, nextMonthYear
	end

	def self.last_week( week, year )
		referenceYear = week == 1 ? year - 1 : year
		maxWeek = Date.new(referenceYear, 12, 28).cweek
		lastWeek = ((week-2) % maxWeek)+1
		lastWeekYear = lastWeek < week ? year : year - 1
		return lastWeek, lastWeekYear
	end

	def self.next_week( week, year)
		maxWeek = Date.new(year, 12, 28).cweek
		nextWeek = (week % maxWeek)+1
		nextWeekYear = nextWeek > week ? year : year + 1
		return nextWeek, nextWeekYear
	end

	def self.days_past_in_year( year )
		currentYear = Date.today.year
		if year < currentYear
			return Date.new(year,12,31).yday
		elsif year = currentYear
			return Date.today.yday
		else
			return 0
		end
	end
end