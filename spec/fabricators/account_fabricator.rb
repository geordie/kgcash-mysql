Fabricator(:account, :class_name => "Account") do
	id { sequence }
	name { Faker::Name.first_name }
	account_type { %w(Asset Expense Income Liability).sample }
end