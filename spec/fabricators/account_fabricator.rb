Fabricator(:account, :class_name => "Account") do
	id { sequence }
	name { Faker::Name.first_name }
	account_type { %w(Asset Expense Income Liability).sample }
end

Fabricator(:asset, from: :account) do
	account_type { "Asset"}
end

Fabricator(:expense, from: :account) do
	account_type { "Expense"}
end

Fabricator(:income, from: :account) do
	account_type { "Income"}
end

Fabricator(:liability, from: :account) do
	account_type { "Liability"}
end

