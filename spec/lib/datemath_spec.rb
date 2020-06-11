require 'spec_helper'
require 'date_math'

describe "DateMath" do
	it "gets last month correctly from first month" do
		expect( DateMath.last_month(1,2020) ).to eq([12,2019])
	end

	it "gets last month correctly from final month" do
		expect( DateMath.last_month(12,2020) ).to eq([11,2020])
	end

	it "gets next month correctly from final month" do
		expect( DateMath.next_month(12,2020) ).to eq([1,2021])
	end

	it "gets next month correctly from first month" do
		expect( DateMath.next_month(1,2020) ).to eq([2,2020])
	end

	it "gets last week correctly from first week" do
		expect( DateMath.last_week(1,2020) ).to eq([52,2019])
	end

	it "gets last week correctly from final week" do
		expect( DateMath.last_week(52,2020) ).to eq([51,2020])
	end

	it "gets next week correctly from final week" do
		expect( DateMath.next_week(53,2020) ).to eq([1,2021])
	end

	it "gets next week correctly from first week" do
		expect( DateMath.next_week(1,2020) ).to eq([2,2020])
	end

	it "gets the days past in the specified year" do
		today = DateTime.now()
		expect( DateMath.days_past_in_year(today.year)).to eq(today.yday)
		expect( DateMath.days_past_in_year(2019)).to eq(365)
		expect( DateMath.days_past_in_year(2016)).to eq(366)
		expect( DateMath.days_past_in_year(3000)).to eq(0)
	end
end