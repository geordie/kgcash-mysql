# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#

users = User.create([
    {username: 'example', email: 'geordie.a.henderson@gmail.com', crypted_password: "$2a$10$Ub1mJwax0nZpN5JU9ED5eu4EE.ad1.95K1dXi.J8DAdLBHPDn6oi6", salt: 'VTKmPVJFsaivMbFxVv5F'}
  ])

puts 'DONE SEED'

#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
