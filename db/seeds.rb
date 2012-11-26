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
  [{ name: 'Childcare', user_id: users[0] },
  { name: 'Groceries', user_id: users[0] },
  { name: 'Utilities', user_id: users[0] },
  { name: 'Gas', user_id: users[0] },
  { name: 'Bucc Bay 57', user_id: users[0] },
  { name: 'House', user_id: users[0] },
  { name: 'Medical', user_id: users[0] },
  { name: 'Dining', user_id: users[0] },
  { name: 'Katie', user_id: users[0] },
  { name: 'Clothing', user_id: users[0] },
  { name: 'Savings', user_id: users[0] },
  { name: 'Bucc Bay 58', user_id: users[0] },
  { name: 'Geordie', user_id: users[0] },
  { name: 'Car', user_id: users[0] },
  { name: 'House Cleaning', user_id: users[0] },
  { name: 'Travel', user_id: users[0] },
  { name: 'Kids', user_id: users[0] },
  { name: 'Royal Van', user_id: users[0] },
  { name: 'Gifts', user_id: users[0] },
  { name: 'RESP', user_id: users[0] },
  { name: 'Tennis Club', user_id: users[0] },
  { name: 'Mobile Phone', user_id: users[0] },
  { name: 'Gifts', user_id: users[0] },
  { name: 'Salary - Katie', user_id: users[0] },
  { name: 'Salary - Geordie', user_id: users[0] },
  { name: 'Salary - Kids', user_id: users[0] },
  { name: 'Not defined', user_id: users[0] },
  { name: 'Beer and Wine', user_id: users[0]}])

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

transactions = Transaction.create([
  {tx_hash:'abc',   tx_date:DateTime.now, debit:100.23, category_id:categories[0], user_id:users[0]},
  {tx_hash:'defg', tx_date:DateTime.now, debit: 56.78, category_id:categories[1], user_id:users[0]},
  {tx_hash:'hij',  tx_date:DateTime.now, debit: 18.68, category_id:categories[2], user_id:users[0]}
  ])

puts 'DONE SEED'

#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
