Fabricator(:application, :class_name => "Doorkeeper::Application") do
  id { sequence }
  name { "admin" }
  uid { "sdfsdfsdf"	 }
  secret { "whatever" }
  redirect_uri { "http://localhost:3000" }
  owner_id { 1 }
end