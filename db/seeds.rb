# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#

users = User.create([
    {username: 'geordie', email: 'geordie.a.henderson@gmail.com', crypted_password: "$2a$10$Ub1mJwax0nZpN5JU9ED5eu4EE.ad1.95K1dXi.J8DAdLBHPDn6oi6", salt: 'VTKmPVJFsaivMbFxVv5F'}
  ])

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

budgetcategories = BudgetCategory.create([
 {amount:2800, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[0].id },
 {amount:850, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[1].id },
 {amount:350, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[2].id },
 {amount:200, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[3].id },
 {amount:100, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[4].id },
 {amount:850, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[5].id },
 {amount:250, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[6].id },
 {amount:200, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[7].id },
 {amount:400, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[8].id },
 {amount:300, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[9].id },
 {amount:500, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[10].id },
 {amount:400, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[11].id },
 {amount:400, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[12].id },
 {amount:300, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[13].id },
 {amount:275, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[14].id },
 {amount:200, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[15].id },
 {amount:200, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[16].id },
 {amount:175, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[17].id },
 {amount:150, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[18].id }
  ])

puts 'DONE SEED'

#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
