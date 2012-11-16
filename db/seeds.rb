# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#

users = User.create([{username: 'geordie', email: 'geordie.a.henderson@gmail.com', crypted_password: '$2a$10$Ub1mJwax0nZpN5JU9ED5eu4EE.ad1.95K1dXi.J8DAdLBHPDn6oi6', salt: 'VTKmPVJFsaivMbFxVv5F'} ])
budgets = Budget.create([{name: 'joint', description: 'kt and geordie joint', user_id: users[0]}])

categories = Category.create(
  [{ name: 'Childcare' },
  { name: 'Groceries' },
  { name: 'Utilities' },
  { name: 'Gas' },
  { name: 'Bucc Bay 57' },
  { name: 'House' },
  { name: 'Medical' },
  { name: 'Dining' },
  { name: 'Katie' },
  { name: 'Clothing' },
  { name: 'Savings' },
  { name: 'Bucc Bay 58' },
  { name: 'Geordie' },
  { name: 'Car' },
  { name: 'House Cleaning' },
  { name: 'Travel' },
  { name: 'Kids' },
  { name: 'Royal Van' },
  { name: 'Gifts' },
  { name: 'RESP' },
  { name: 'Tennis Club' },
  { name: 'Mobile Phone' },
  { name: 'Gifts' },
  { name: 'Salary - Katie' },
  { name: 'Salary - Geordie' },
  { name: 'Salary - Kids' },
  { name: 'Not defined' },
  { name: 'Beer and Wine'}])

budgetcategories = BudgetCategory.create([{amount:800, period:'MONTHLY', budget_id: budgets[0], category_id: categories[1] }])
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
