Fabricator(:user, :class_name => "User") do
	accounts(count: 9){
		|attrs, i|
			case i
			when 1..2
				Fabricate(:asset)
			when 3..4
				Fabricate(:liability)
			when 5..6
				Fabricate(:income)
			when 7..9
				Fabricate(:expense)
			else
				Fabricate(:expense)
			end
	}
	username { sequence(:username) { |i| "user#{i}" } }
	password { "admin" }
	email { sequence(:email) { |i| "user#{i}@example.com" } }
	salt { "asdasdastr4325234324sdfds" }
	crypted_password { Sorcery::CryptoProviders::BCrypt.encrypt("secret", "asdasdastr4325234324sdfds") }
end