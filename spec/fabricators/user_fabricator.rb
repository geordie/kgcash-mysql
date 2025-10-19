Fabricator(:user, :class_name => "User") do
	username { sequence(:username) { |i| "user#{i}" } }
	password { "admin" }
	email { sequence(:email) { |i| "user#{i}@example.com" } }
	salt { "asdasdastr4325234324sdfds" }
	crypted_password { Sorcery::CryptoProviders::BCrypt.encrypt("secret", "asdasdastr4325234324sdfds") }

	after_create { |user|
		# Create accounts for the user
		2.times { Fabricate(:asset, user: user) }
		2.times { Fabricate(:liability, user: user) }
		2.times { Fabricate(:income, user: user) }
		3.times { Fabricate(:expense, user: user) }
	}
end

# User without auto-created accounts, for tests that need explicit control
Fabricator(:user_without_accounts, from: :user) do
	after_create { }
end