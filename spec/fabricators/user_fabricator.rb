Fabricator(:user, :class_name => "User") do
	id { sequence }
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
	username { "admin" }
	password { "admin" }
	email { "whatever@whatever.com" }
	salt { "asdasdastr4325234324sdfds" }
	crypted_password { Sorcery::CryptoProviders::BCrypt.encrypt("secret", "asdasdastr4325234324sdfds") }
end