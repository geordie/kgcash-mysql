# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#

users = User.create([
    {username: 'example', email: 'geordie.a.henderson@gmail.com', crypted_password: "$2a$10$Ub1mJwax0nZpN5JU9ED5eu4EE.ad1.95K1dXi.J8DAdLBHPDn6oi6", salt: 'VTKmPVJFsaivMbFxVv5F'}
  ])

budgets = Budget.create([{name: 'Example Budget', description: 'A basic example budget', user_id: users[0]}])

categories = Category.create([
{ name: 'Clothing', user_id: users[0] },
{ name: 'Dining', user_id: users[0] },
{ name: 'Discretionary', user_id: users[0] },
{ name: 'Groceries', user_id: users[0] },
{ name: 'Gifts', user_id: users[0] },
{ name: 'Home', user_id: users[0] },
{ name: 'Insurance', user_id: users[0] },
{ name: 'Internet', user_id: users[0] },
{ name: 'Medical', user_id: users[0] },
{ name: 'Rent', user_id: users[0] },
{ name: 'Phone', user_id: users[0] },
{ name: 'Property Tax', user_id: users[0] },
{ name: 'Savings', user_id: users[0] },
{ name: 'Transportation', user_id: users[0] },
{ name: 'Travel', user_id: users[0] },
{ name: 'Utilities', user_id: users[0] }])

budgetcategories = BudgetCategory.create([
 {amount:200, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[0].id },
 {amount:300, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[1].id },
 {amount:250, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[2].id },
 {amount:500, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[3].id },
 {amount:100, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[4].id },
 {amount:200, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[5].id },
 {amount:100, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[6].id },
 {amount:100, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[7].id },
 {amount:1200, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[8].id },
 {amount:75, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[9].id },
 {amount:100, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[10].id },
 {amount:300, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[11].id },
 {amount:300, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[12].id },
 {amount:300, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[13].id },
 {amount:300, period:'MONTHLY', budget_id: budgets[0].id, category_id: categories[14].id }
  ])

#transactions = Transaction.create([
#  {tx_hash:'abc',   tx_date:DateTime.now, debit:100.23, category_id:categories[0], user_id:users[0]},
#  {tx_hash:'defg', tx_date:DateTime.now, debit: 56.78, category_id:categories[1], user_id:users[0]},
#  {tx_hash:'hij',  tx_date:DateTime.now, debit: 18.68, category_id:categories[2], user_id:users[0]}
#  ])

puts 'DONE SEED'

#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
