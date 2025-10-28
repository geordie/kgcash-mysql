require 'spec_helper'

# Regression Baseline Suite
#
# This suite captures current behavior as a baseline.
# These tests MUST pass both before and after the migration to ensure
# that the migration preserves all existing functionality.
#
# Tag: :regression - Run with: bundle exec rspec --tag regression

RSpec.describe 'Transaction behavior baseline (pre-migration)', :regression do

  describe 'Data integrity' do
    it 'maintains total debit = total credit across all transactions' do
      user = Fabricate(:user)
      bank = user.accounts.find { |a| a.account_type == 'Asset' }
      expense1 = user.accounts.find { |a| a.account_type == 'Expense' }

      # Create various transactions with different amounts
      transactions_data = [
        { debit: 25.50, credit: 25.50 },
        { debit: 100.00, credit: 100.00 },
        { debit: 47.33, credit: 47.33 },
        { debit: 200.00, credit: 200.00 },
        { debit: 15.99, credit: 15.99 },
        { debit: 333.33, credit: 333.33 },
        { debit: 50.00, credit: 50.00 },
        { debit: 12.75, credit: 12.75 },
        { debit: 88.88, credit: 88.88 },
        { debit: 125.00, credit: 125.00 }
      ]

      transactions_data.each do |tx_data|
        Transaction.create!(
          user: user,
          tx_date: Date.today,
          acct_id_dr: expense1.id,
          debit: tx_data[:debit],
          acct_id_cr: bank.id,
          credit: tx_data[:credit]
        )
      end

      total_debits = user.transactions.sum(:debit)
      total_credits = user.transactions.sum(:credit)

      expect(total_debits).to eq(total_credits)
      expect(total_debits).to eq(998.78) # Sum of all debits above
    end

    it 'maintains debit = credit balance for each individual transaction' do
      user = Fabricate(:user)
      bank = user.accounts.find { |a| a.account_type == 'Asset' }
      expense = user.accounts.find { |a| a.account_type == 'Expense' }

      # Create transactions
      20.times do
        amount = rand(10.0..500.0).round(2)
        Transaction.create!(
          user: user,
          tx_date: Date.today - rand(1..365).days,
          acct_id_dr: expense.id,
          debit: amount,
          acct_id_cr: bank.id,
          credit: amount
        )
      end

      # Verify each transaction is balanced
      user.transactions.each do |txn|
        # Either both sides have same amount, or one side is nil (uncategorized)
        if txn.debit && txn.credit
          expect(txn.debit).to eq(txn.credit),
            "Transaction #{txn.id} is unbalanced: debit=#{txn.debit}, credit=#{txn.credit}"
        end
      end
    end

    it 'correctly handles NULL accounts without breaking balance integrity' do
      user = Fabricate(:user)
      bank = user.accounts.find { |a| a.account_type == 'Asset' }

      # Create uncategorized expense (NULL debit account)
      Transaction.create!(
        user: user,
        tx_date: Date.today,
        acct_id_dr: nil,  # Uncategorized
        debit: nil,
        acct_id_cr: bank.id,
        credit: 50.00
      )

      # Create uncategorized income (NULL credit account)
      Transaction.create!(
        user: user,
        tx_date: Date.today,
        acct_id_dr: bank.id,
        debit: 100.00,
        acct_id_cr: nil,  # Uncategorized
        credit: nil
      )

      # Total credits should only count non-NULL values
      total_credits = user.transactions.sum(:credit)
      total_debits = user.transactions.sum(:debit)

      expect(total_credits).to eq(50.00)
      expect(total_debits).to eq(100.00)
    end
  end

  describe 'Report generation consistency' do
    let(:user) { Fabricate(:user) }
    let(:bank) do
      user.accounts.find { |a| a.account_type == 'Asset' } || Fabricate(:asset, user: user)
    end
    let(:groceries) do
      Fabricate(:expense, name: 'Groceries', user: user)
    end
    let(:utilities) do
      Fabricate(:expense, name: 'Utilities', user: user)
    end
    let(:salary) do
      Fabricate(:income, name: 'Salary', user: user)
    end

    it 'generates consistent expense reports matching sum of individual transactions' do
      # Create test data
      Transaction.create!(user: user, tx_date: Date.today, acct_id_dr: groceries.id, debit: 100, acct_id_cr: bank.id, credit: 100)
      Transaction.create!(user: user, tx_date: Date.today, acct_id_dr: utilities.id, debit: 50, acct_id_cr: bank.id, credit: 50)
      Transaction.create!(user: user, tx_date: Date.today, acct_id_dr: groceries.id, debit: 75, acct_id_cr: bank.id, credit: 75)

      # Generate report using query method
      results = Transaction.expenses_by_category(user, Date.today.year, Date.today.month)

      # Verify totals match sum of individual transactions
      grocery_result = results.find { |r| r.name == 'Groceries' }
      utility_result = results.find { |r| r.name == 'Utilities' }

      expect(grocery_result.expenses).to eq(175)  # 100 + 75
      expect(utility_result.expenses).to eq(50)

      # Verify total of report matches sum of all expenses
      total_from_report = results.sum(&:expenses)
      total_from_db = user.transactions
        .where(acct_id_dr: [groceries.id, utilities.id])
        .sum(:debit)

      expect(total_from_report).to eq(total_from_db)
      expect(total_from_report).to eq(225)
    end

    it 'generates consistent income reports matching sum of individual transactions' do
      # Create test income transactions
      Transaction.create!(user: user, tx_date: Date.today, acct_id_dr: bank.id, debit: 2000, acct_id_cr: salary.id, credit: 2000)
      Transaction.create!(user: user, tx_date: Date.today, acct_id_dr: bank.id, debit: 500, acct_id_cr: salary.id, credit: 500)

      # Generate report
      results = Transaction.income_by_category(user, Date.today.year, Date.today.month)

      # Verify totals
      salary_result = results.find { |r| r.name == 'Salary' }
      expect(salary_result.income).to eq(2500)  # 2000 + 500

      # Verify total matches DB sum
      total_from_db = user.transactions
        .where(acct_id_cr: salary.id)
        .sum(:credit)

      expect(salary_result.income).to eq(total_from_db)
    end

    it 'generates consistent all-time expense reports' do
      # Create expenses across multiple months
      Transaction.create!(user: user, tx_date: Date.new(2024, 1, 15), acct_id_dr: groceries.id, debit: 100, acct_id_cr: bank.id, credit: 100)
      Transaction.create!(user: user, tx_date: Date.new(2024, 6, 15), acct_id_dr: groceries.id, debit: 150, acct_id_cr: bank.id, credit: 150)
      Transaction.create!(user: user, tx_date: Date.new(2024, 12, 15), acct_id_dr: utilities.id, debit: 75, acct_id_cr: bank.id, credit: 75)

      # Generate all-time report
      results = Transaction.expenses_all_time(user, 2024)

      # Verify total
      expect(results.first.expenses).to eq(325)  # 100 + 150 + 75

      # Verify matches DB sum
      total_from_db = user.transactions
        .where('YEAR(tx_date) = ?', 2024)
        .where(acct_id_dr: [groceries.id, utilities.id])
        .sum(:debit)

      expect(results.first.expenses).to eq(total_from_db)
    end

    it 'generates consistent all-time revenue reports' do
      # Create income across multiple months
      Transaction.create!(user: user, tx_date: Date.new(2024, 1, 15), acct_id_dr: bank.id, debit: 2000, acct_id_cr: salary.id, credit: 2000)
      Transaction.create!(user: user, tx_date: Date.new(2024, 6, 15), acct_id_dr: bank.id, debit: 2000, acct_id_cr: salary.id, credit: 2000)
      Transaction.create!(user: user, tx_date: Date.new(2024, 12, 15), acct_id_dr: bank.id, debit: 2500, acct_id_cr: salary.id, credit: 2500)

      # Generate all-time report
      results = Transaction.revenues_all_time(user, 2024)

      # Verify total
      expect(results.first.revenue).to eq(6500)  # 2000 + 2000 + 2500

      # Verify matches DB sum
      total_from_db = user.transactions
        .where('YEAR(tx_date) = ?', 2024)
        .where(acct_id_cr: salary.id)
        .sum(:credit)

      expect(results.first.revenue).to eq(total_from_db)
    end
  end

  describe 'Account balance calculations' do
    let(:user) { Fabricate(:user) }
    let(:bank) do
      Fabricate(:asset, name: 'Checking', user: user)
    end
    let(:groceries) do
      Fabricate(:expense, name: 'Groceries', user: user)
    end
    let(:salary) do
      Fabricate(:income, name: 'Salary', user: user)
    end

    it 'account balances match sum of transaction entries' do
      year = Date.today.year

      # Create income (debits to bank)
      Transaction.create!(user: user, tx_date: Date.today, acct_id_dr: bank.id, debit: 3000, acct_id_cr: salary.id, credit: 3000)
      Transaction.create!(user: user, tx_date: Date.today, acct_id_dr: bank.id, debit: 500, acct_id_cr: salary.id, credit: 500)

      # Create expenses (credits from bank)
      Transaction.create!(user: user, tx_date: Date.today, acct_id_dr: groceries.id, debit: 200, acct_id_cr: bank.id, credit: 200)
      Transaction.create!(user: user, tx_date: Date.today, acct_id_dr: groceries.id, debit: 150, acct_id_cr: bank.id, credit: 150)

      # Verify bank account balance
      bank_debits = bank.debits(year)
      bank_credits = bank.credits(year)

      expect(bank_debits).to eq(3500)   # Income: 3000 + 500
      expect(bank_credits).to eq(350)   # Expenses: 200 + 150

      # Net balance should be 3500 - 350 = 3150 (positive for asset account)

      # Verify expense account balance
      groceries_debits = groceries.debits(year)
      expect(groceries_debits).to eq(350)  # 200 + 150

      # Verify income account balance
      salary_credits = salary.credits(year)
      expect(salary_credits).to eq(3500)  # 3000 + 500

      # Verify manual sum matches account method
      manual_bank_debits = user.transactions.where(acct_id_dr: bank.id).where('YEAR(tx_date) = ?', year).sum(:debit)
      manual_bank_credits = user.transactions.where(acct_id_cr: bank.id).where('YEAR(tx_date) = ?', year).sum(:credit)

      expect(bank_debits).to eq(manual_bank_debits)
      expect(bank_credits).to eq(manual_bank_credits)
    end

    it 'account monthly aggregations are consistent' do
      year = 2024

      # Create transactions in different months
      Transaction.create!(user: user, tx_date: Date.new(2024, 1, 15), acct_id_dr: groceries.id, debit: 100, acct_id_cr: bank.id, credit: 100)
      Transaction.create!(user: user, tx_date: Date.new(2024, 1, 20), acct_id_dr: groceries.id, debit: 50, acct_id_cr: bank.id, credit: 50)
      Transaction.create!(user: user, tx_date: Date.new(2024, 2, 15), acct_id_dr: groceries.id, debit: 200, acct_id_cr: bank.id, credit: 200)
      Transaction.create!(user: user, tx_date: Date.new(2024, 3, 15), acct_id_dr: groceries.id, debit: 75, acct_id_cr: bank.id, credit: 75)

      # Get monthly breakdown
      monthly_debits = groceries.debits_monthly(year)

      expect(monthly_debits[1]).to eq(150)  # January: 100 + 50
      expect(monthly_debits[2]).to eq(200)  # February
      expect(monthly_debits[3]).to eq(75)   # March

      # Verify sum of monthly equals yearly total
      monthly_sum = monthly_debits.values.sum
      yearly_total = groceries.debits(year)

      expect(monthly_sum).to eq(yearly_total)
      expect(yearly_total).to eq(425)
    end

    it 'account yearly aggregations are consistent' do
      # Create transactions across multiple years
      Transaction.create!(user: user, tx_date: Date.new(2023, 6, 15), acct_id_dr: groceries.id, debit: 100, acct_id_cr: bank.id, credit: 100)
      Transaction.create!(user: user, tx_date: Date.new(2024, 6, 15), acct_id_dr: groceries.id, debit: 200, acct_id_cr: bank.id, credit: 200)
      Transaction.create!(user: user, tx_date: Date.new(2025, 6, 15), acct_id_dr: groceries.id, debit: 300, acct_id_cr: bank.id, credit: 300)

      # Get yearly breakdown
      yearly_debits = groceries.debits_yearly(10)

      expect(yearly_debits[2023]).to eq(100)
      expect(yearly_debits[2024]).to eq(200)
      expect(yearly_debits[2025]).to eq(300)

      # Verify each year individually
      expect(groceries.debits(2023)).to eq(100)
      expect(groceries.debits(2024)).to eq(200)
      expect(groceries.debits(2025)).to eq(300)
    end
  end

  describe 'Date filtering consistency' do
    let(:user) { Fabricate(:user) }
    let(:bank) do
      Fabricate(:asset, name: 'Checking', user: user)
    end
    let(:groceries) do
      Fabricate(:expense, name: 'Groceries', user: user)
    end

    it 'produces consistent results when filtering by year' do
      # Create transactions in different years
      Transaction.create!(user: user, tx_date: Date.new(2023, 6, 15), acct_id_dr: groceries.id, debit: 100, acct_id_cr: bank.id, credit: 100)
      Transaction.create!(user: user, tx_date: Date.new(2024, 6, 15), acct_id_dr: groceries.id, debit: 200, acct_id_cr: bank.id, credit: 200)
      Transaction.create!(user: user, tx_date: Date.new(2024, 12, 15), acct_id_dr: groceries.id, debit: 150, acct_id_cr: bank.id, credit: 150)

      # Filter by year using scope
      txns_2024 = user.transactions.in_year(2024)

      expect(txns_2024.count).to eq(2)
      expect(txns_2024.sum(:debit)).to eq(350)  # 200 + 150

      # Verify consistency with account method
      groceries_2024 = groceries.debits(2024)
      expect(groceries_2024).to eq(350)
    end

    it 'produces consistent results when filtering by month and year' do
      # Create transactions in different months of same year
      Transaction.create!(user: user, tx_date: Date.new(2024, 1, 15), acct_id_dr: groceries.id, debit: 100, acct_id_cr: bank.id, credit: 100)
      Transaction.create!(user: user, tx_date: Date.new(2024, 6, 15), acct_id_dr: groceries.id, debit: 200, acct_id_cr: bank.id, credit: 200)
      Transaction.create!(user: user, tx_date: Date.new(2024, 6, 20), acct_id_dr: groceries.id, debit: 50, acct_id_cr: bank.id, credit: 50)

      # Filter by month and year using scope
      txns_june_2024 = user.transactions.in_month_year(6, 2024)

      expect(txns_june_2024.count).to eq(2)
      expect(txns_june_2024.sum(:debit)).to eq(250)  # 200 + 50

      # Verify consistency with report method
      expense_report = Transaction.expenses_by_category(user, 2024, 6)
      groceries_june = expense_report.find { |r| r.name == 'Groceries' }

      expect(groceries_june.expenses).to eq(250)
    end
  end

  describe 'Baseline metrics capture' do
    let(:user) { Fabricate(:user) }
    let(:bank) do
      Fabricate(:asset, name: 'Checking', user: user)
    end
    let(:groceries) do
      Fabricate(:expense, name: 'Groceries', user: user)
    end
    let(:salary) do
      Fabricate(:income, name: 'Salary', user: user)
    end

    it 'captures baseline expense totals for comparison post-migration' do
      year = 2024
      month = 10

      # Create known expense data
      Transaction.create!(user: user, tx_date: Date.new(year, month, 1), acct_id_dr: groceries.id, debit: 100, acct_id_cr: bank.id, credit: 100)
      Transaction.create!(user: user, tx_date: Date.new(year, month, 15), acct_id_dr: groceries.id, debit: 200, acct_id_cr: bank.id, credit: 200)

      # Capture baseline
      baseline_monthly = Transaction.expenses_by_category(user, year, month)
      baseline_yearly = Transaction.expenses_all_time(user, year)

      groceries_monthly = baseline_monthly.find { |r| r.name == 'Groceries' }

      # Document baseline values
      expect(groceries_monthly.expenses).to eq(300)
      expect(baseline_yearly.first.expenses).to eq(300)

      # These values MUST remain the same after migration
      puts "\n=== BASELINE METRICS (#{year}-#{month}) ==="
      puts "Groceries expenses (monthly): $#{groceries_monthly.expenses}"
      puts "Total expenses (yearly): $#{baseline_yearly.first.expenses}"
      puts "====================================\n"
    end

    it 'captures baseline income totals for comparison post-migration' do
      year = 2024
      month = 10

      # Create known income data
      Transaction.create!(user: user, tx_date: Date.new(year, month, 1), acct_id_dr: bank.id, debit: 2000, acct_id_cr: salary.id, credit: 2000)
      Transaction.create!(user: user, tx_date: Date.new(year, month, 15), acct_id_dr: bank.id, debit: 500, acct_id_cr: salary.id, credit: 500)

      # Capture baseline
      baseline_monthly = Transaction.income_by_category(user, year, month)
      baseline_yearly = Transaction.revenues_all_time(user, year)

      salary_monthly = baseline_monthly.find { |r| r.name == 'Salary' }

      # Document baseline values
      expect(salary_monthly.income).to eq(2500)
      expect(baseline_yearly.first.revenue).to eq(2500)

      # These values MUST remain the same after migration
      puts "\n=== BASELINE METRICS (#{year}-#{month}) ==="
      puts "Salary income (monthly): $#{salary_monthly.income}"
      puts "Total revenue (yearly): $#{baseline_yearly.first.revenue}"
      puts "====================================\n"
    end

    it 'captures baseline account balances for comparison post-migration' do
      year = 2024

      # Create known transaction history
      Transaction.create!(user: user, tx_date: Date.new(year, 1, 1), acct_id_dr: bank.id, debit: 5000, acct_id_cr: salary.id, credit: 5000)
      Transaction.create!(user: user, tx_date: Date.new(year, 6, 15), acct_id_dr: groceries.id, debit: 300, acct_id_cr: bank.id, credit: 300)
      Transaction.create!(user: user, tx_date: Date.new(year, 12, 15), acct_id_dr: groceries.id, debit: 200, acct_id_cr: bank.id, credit: 200)

      # Capture baseline balances
      bank_debits = bank.debits(year)
      bank_credits = bank.credits(year)
      groceries_debits = groceries.debits(year)
      salary_credits = salary.credits(year)

      # Document baseline values
      expect(bank_debits).to eq(5000)
      expect(bank_credits).to eq(500)
      expect(groceries_debits).to eq(500)
      expect(salary_credits).to eq(5000)

      # These values MUST remain the same after migration
      puts "\n=== BASELINE ACCOUNT BALANCES (#{year}) ==="
      puts "Bank debits: $#{bank_debits}"
      puts "Bank credits: $#{bank_credits}"
      puts "Bank net: $#{bank_debits - bank_credits}"
      puts "Groceries total: $#{groceries_debits}"
      puts "Salary total: $#{salary_credits}"
      puts "====================================\n"
    end
  end
end
