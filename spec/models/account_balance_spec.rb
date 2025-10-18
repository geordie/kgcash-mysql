require 'spec_helper'

RSpec.describe Account, type: :model do
  describe 'Account balance calculations' do
    let(:user) { Fabricate(:user) }
    let(:bank_account) do
      account = Fabricate(:asset, name: 'Checking Account')
      user.accounts << account unless user.accounts.include?(account)
      account
    end
    let(:credit_card_account) do
      account = Fabricate(:liability, name: 'Visa Card')
      user.accounts << account unless user.accounts.include?(account)
      account
    end
    let(:groceries_account) do
      account = Fabricate(:expense, name: 'Groceries')
      user.accounts << account unless user.accounts.include?(account)
      account
    end
    let(:salary_account) do
      account = Fabricate(:income, name: 'Salary')
      user.accounts << account unless user.accounts.include?(account)
      account
    end

    describe 'Asset account balances' do
      it 'increases with debits, decreases with credits' do
        # Money coming in (debit to asset)
        Transaction.create!(
          user: user,
          tx_date: Date.today,
          details: 'Salary deposit',
          acct_id_dr: bank_account.id,
          debit: 1000.00,
          acct_id_cr: salary_account.id,
          credit: 1000.00
        )

        # Money going out (credit to asset)
        Transaction.create!(
          user: user,
          tx_date: Date.today,
          details: 'Grocery purchase',
          acct_id_dr: groceries_account.id,
          debit: 50.00,
          acct_id_cr: bank_account.id,
          credit: 50.00
        )

        # Asset increases with debits
        expect(bank_account.debits(Date.today.year)).to eq(1000.00)
        # Asset decreases with credits
        expect(bank_account.credits(Date.today.year)).to eq(50.00)
        # Net asset balance: 1000 - 50 = 950 (positive/debit balance)
      end

      it 'correctly tracks multiple debit transactions' do
        3.times do |i|
          Transaction.create!(
            user: user,
            tx_date: Date.today,
            details: "Deposit #{i+1}",
            acct_id_dr: bank_account.id,
            debit: 100.00 * (i + 1),
            acct_id_cr: salary_account.id,
            credit: 100.00 * (i + 1)
          )
        end

        # Should sum: 100 + 200 + 300 = 600
        expect(bank_account.debits(Date.today.year)).to eq(600.00)
      end

      it 'correctly tracks multiple credit transactions' do
        # Start with some money
        Transaction.create!(
          user: user,
          tx_date: Date.today,
          details: 'Initial deposit',
          acct_id_dr: bank_account.id,
          debit: 1000.00,
          acct_id_cr: salary_account.id,
          credit: 1000.00
        )

        # Multiple withdrawals
        3.times do |i|
          Transaction.create!(
            user: user,
            tx_date: Date.today,
            details: "Expense #{i+1}",
            acct_id_dr: groceries_account.id,
            debit: 50.00,
            acct_id_cr: bank_account.id,
            credit: 50.00
          )
        end

        # Should sum: 50 + 50 + 50 = 150
        expect(bank_account.credits(Date.today.year)).to eq(150.00)
      end
    end

    describe 'Liability account balances' do
      it 'increases with credits, decreases with debits' do
        # Charge to credit card (credit to liability - increases debt)
        Transaction.create!(
          user: user,
          tx_date: Date.today,
          details: 'Purchase on credit',
          acct_id_dr: groceries_account.id,
          debit: 100.00,
          acct_id_cr: credit_card_account.id,
          credit: 100.00
        )

        # Pay off credit card (debit to liability - decreases debt)
        Transaction.create!(
          user: user,
          tx_date: Date.today,
          details: 'Credit card payment',
          acct_id_dr: credit_card_account.id,
          debit: 50.00,
          acct_id_cr: bank_account.id,
          credit: 50.00
        )

        # Liability increases with credits
        expect(credit_card_account.credits(Date.today.year)).to eq(100.00)
        # Liability decreases with debits
        expect(credit_card_account.debits(Date.today.year)).to eq(50.00)
        # Net liability balance: 100 - 50 = 50 (you still owe $50)
      end

      it 'correctly tracks multiple charges (credits)' do
        3.times do |i|
          Transaction.create!(
            user: user,
            tx_date: Date.today,
            details: "Credit card purchase #{i+1}",
            acct_id_dr: groceries_account.id,
            debit: 75.00,
            acct_id_cr: credit_card_account.id,
            credit: 75.00
          )
        end

        # Should sum: 75 + 75 + 75 = 225
        expect(credit_card_account.credits(Date.today.year)).to eq(225.00)
      end

      it 'correctly tracks multiple payments (debits)' do
        # Charge card
        Transaction.create!(
          user: user,
          tx_date: Date.today,
          details: 'Big purchase',
          acct_id_dr: groceries_account.id,
          debit: 500.00,
          acct_id_cr: credit_card_account.id,
          credit: 500.00
        )

        # Multiple payments
        2.times do |i|
          Transaction.create!(
            user: user,
            tx_date: Date.today,
            details: "Payment #{i+1}",
            acct_id_dr: credit_card_account.id,
            debit: 100.00,
            acct_id_cr: bank_account.id,
            credit: 100.00
          )
        end

        # Should sum: 100 + 100 = 200
        expect(credit_card_account.debits(Date.today.year)).to eq(200.00)
      end
    end

    describe 'Expense account balances' do
      it 'increases with debits' do
        3.times do |i|
          Transaction.create!(
            user: user,
            tx_date: Date.today,
            details: "Grocery trip #{i+1}",
            acct_id_dr: groceries_account.id,
            debit: 40.00 + (i * 10),
            acct_id_cr: bank_account.id,
            credit: 40.00 + (i * 10)
          )
        end

        # Should sum: 40 + 50 + 60 = 150
        expect(groceries_account.debits(Date.today.year)).to eq(150.00)
      end

      it 'should not have credit transactions' do
        # Expenses should only be debited, never credited
        Transaction.create!(
          user: user,
          tx_date: Date.today,
          details: 'Expense',
          acct_id_dr: groceries_account.id,
          debit: 100.00,
          acct_id_cr: bank_account.id,
          credit: 100.00
        )

        expect(groceries_account.credits(Date.today.year)).to eq(0.00)
      end

      it 'correctly sums multiple expense categories' do
        utilities_account = Fabricate(:expense, name: 'Utilities')
        user.accounts << utilities_account

        Transaction.create!(
          user: user,
          tx_date: Date.today,
          details: 'Groceries',
          acct_id_dr: groceries_account.id,
          debit: 100.00,
          acct_id_cr: bank_account.id,
          credit: 100.00
        )

        Transaction.create!(
          user: user,
          tx_date: Date.today,
          details: 'Electric bill',
          acct_id_dr: utilities_account.id,
          debit: 75.00,
          acct_id_cr: bank_account.id,
          credit: 75.00
        )

        expect(groceries_account.debits(Date.today.year)).to eq(100.00)
        expect(utilities_account.debits(Date.today.year)).to eq(75.00)
      end
    end

    describe 'Income account balances' do
      it 'increases with credits' do
        3.times do |i|
          Transaction.create!(
            user: user,
            tx_date: Date.today,
            details: "Paycheck #{i+1}",
            acct_id_dr: bank_account.id,
            debit: 1500.00,
            acct_id_cr: salary_account.id,
            credit: 1500.00
          )
        end

        # Should sum: 1500 + 1500 + 1500 = 4500
        expect(salary_account.credits(Date.today.year)).to eq(4500.00)
      end

      it 'should not have debit transactions' do
        # Income should only be credited, never debited
        Transaction.create!(
          user: user,
          tx_date: Date.today,
          details: 'Salary',
          acct_id_dr: bank_account.id,
          debit: 2000.00,
          acct_id_cr: salary_account.id,
          credit: 2000.00
        )

        expect(salary_account.debits(Date.today.year)).to eq(0.00)
      end

      it 'correctly sums multiple income categories' do
        bonus_account = Fabricate(:income, name: 'Bonus')
        user.accounts << bonus_account

        Transaction.create!(
          user: user,
          tx_date: Date.today,
          details: 'Regular salary',
          acct_id_dr: bank_account.id,
          debit: 2000.00,
          acct_id_cr: salary_account.id,
          credit: 2000.00
        )

        Transaction.create!(
          user: user,
          tx_date: Date.today,
          details: 'Year-end bonus',
          acct_id_dr: bank_account.id,
          debit: 500.00,
          acct_id_cr: bonus_account.id,
          credit: 500.00
        )

        expect(salary_account.credits(Date.today.year)).to eq(2000.00)
        expect(bonus_account.credits(Date.today.year)).to eq(500.00)
      end
    end

    describe '.debits(year) calculation' do
      it 'returns debits for the specified year' do
        # Transaction in current year
        Transaction.create!(
          user: user,
          tx_date: Date.new(Date.today.year, 6, 15),
          details: 'Current year expense',
          acct_id_dr: groceries_account.id,
          debit: 100.00,
          acct_id_cr: bank_account.id,
          credit: 100.00
        )

        # Transaction in previous year
        Transaction.create!(
          user: user,
          tx_date: Date.new(Date.today.year - 1, 6, 15),
          details: 'Last year expense',
          acct_id_dr: groceries_account.id,
          debit: 200.00,
          acct_id_cr: bank_account.id,
          credit: 200.00
        )

        expect(groceries_account.debits(Date.today.year)).to eq(100.00)
        expect(groceries_account.debits(Date.today.year - 1)).to eq(200.00)
      end

      it 'defaults to current year when no year specified' do
        Transaction.create!(
          user: user,
          tx_date: Date.today,
          details: 'This year',
          acct_id_dr: groceries_account.id,
          debit: 150.00,
          acct_id_cr: bank_account.id,
          credit: 150.00
        )

        expect(groceries_account.debits).to eq(150.00)
        expect(groceries_account.debits(nil)).to eq(150.00)
      end

      it 'returns 0 for years with no transactions' do
        Transaction.create!(
          user: user,
          tx_date: Date.today,
          details: 'Expense',
          acct_id_dr: groceries_account.id,
          debit: 100.00,
          acct_id_cr: bank_account.id,
          credit: 100.00
        )

        # Check a year far in the past
        expect(groceries_account.debits(2000)).to eq(0.00)
      end
    end

    describe '.credits(year) calculation' do
      it 'returns credits for the specified year' do
        # Transaction in current year
        Transaction.create!(
          user: user,
          tx_date: Date.new(Date.today.year, 6, 15),
          details: 'Current year income',
          acct_id_dr: bank_account.id,
          debit: 1000.00,
          acct_id_cr: salary_account.id,
          credit: 1000.00
        )

        # Transaction in previous year
        Transaction.create!(
          user: user,
          tx_date: Date.new(Date.today.year - 1, 6, 15),
          details: 'Last year income',
          acct_id_dr: bank_account.id,
          debit: 2000.00,
          acct_id_cr: salary_account.id,
          credit: 2000.00
        )

        expect(salary_account.credits(Date.today.year)).to eq(1000.00)
        expect(salary_account.credits(Date.today.year - 1)).to eq(2000.00)
      end

      it 'defaults to current year when no year specified' do
        Transaction.create!(
          user: user,
          tx_date: Date.today,
          details: 'Income',
          acct_id_dr: bank_account.id,
          debit: 1500.00,
          acct_id_cr: salary_account.id,
          credit: 1500.00
        )

        expect(salary_account.credits).to eq(1500.00)
        expect(salary_account.credits(nil)).to eq(1500.00)
      end

      it 'returns 0 for years with no transactions' do
        Transaction.create!(
          user: user,
          tx_date: Date.today,
          details: 'Income',
          acct_id_dr: bank_account.id,
          debit: 1000.00,
          acct_id_cr: salary_account.id,
          credit: 1000.00
        )

        # Check a year far in the past
        expect(salary_account.credits(2000)).to eq(0.00)
      end
    end

    describe '.debits_monthly(year) aggregation' do
      it 'aggregates debits by month correctly' do
        # January transaction
        Transaction.create!(
          user: user,
          tx_date: Date.new(Date.today.year, 1, 15),
          details: 'January expense',
          acct_id_dr: groceries_account.id,
          debit: 100.00,
          acct_id_cr: bank_account.id,
          credit: 100.00
        )

        # February transactions (2 of them)
        Transaction.create!(
          user: user,
          tx_date: Date.new(Date.today.year, 2, 10),
          details: 'February expense 1',
          acct_id_dr: groceries_account.id,
          debit: 75.00,
          acct_id_cr: bank_account.id,
          credit: 75.00
        )

        Transaction.create!(
          user: user,
          tx_date: Date.new(Date.today.year, 2, 20),
          details: 'February expense 2',
          acct_id_dr: groceries_account.id,
          debit: 25.00,
          acct_id_cr: bank_account.id,
          credit: 25.00
        )

        # March transaction
        Transaction.create!(
          user: user,
          tx_date: Date.new(Date.today.year, 3, 5),
          details: 'March expense',
          acct_id_dr: groceries_account.id,
          debit: 150.00,
          acct_id_cr: bank_account.id,
          credit: 150.00
        )

        monthly = groceries_account.debits_monthly(Date.today.year)
        
        expect(monthly[1]).to eq(100.00)
        expect(monthly[2]).to eq(100.00)  # 75 + 25
        expect(monthly[3]).to eq(150.00)
      end

      it 'returns empty hash for year with no transactions' do
        monthly = groceries_account.debits_monthly(2000)
        expect(monthly).to be_empty
      end

      it 'defaults to current year when no year specified' do
        Transaction.create!(
          user: user,
          tx_date: Date.today,
          details: 'Current month',
          acct_id_dr: groceries_account.id,
          debit: 200.00,
          acct_id_cr: bank_account.id,
          credit: 200.00
        )

        monthly = groceries_account.debits_monthly
        expect(monthly[Date.today.month]).to eq(200.00)
      end

      it 'only includes transactions from specified year' do
        # Transaction in current year
        Transaction.create!(
          user: user,
          tx_date: Date.new(Date.today.year, 1, 15),
          details: 'This year',
          acct_id_dr: groceries_account.id,
          debit: 100.00,
          acct_id_cr: bank_account.id,
          credit: 100.00
        )

        # Transaction in previous year
        Transaction.create!(
          user: user,
          tx_date: Date.new(Date.today.year - 1, 1, 15),
          details: 'Last year',
          acct_id_dr: groceries_account.id,
          debit: 500.00,
          acct_id_cr: bank_account.id,
          credit: 500.00
        )

        monthly_this_year = groceries_account.debits_monthly(Date.today.year)
        monthly_last_year = groceries_account.debits_monthly(Date.today.year - 1)

        expect(monthly_this_year[1]).to eq(100.00)
        expect(monthly_last_year[1]).to eq(500.00)
      end
    end

    describe '.credits_monthly(year) aggregation' do
      it 'aggregates credits by month correctly' do
        # January transaction
        Transaction.create!(
          user: user,
          tx_date: Date.new(Date.today.year, 1, 31),
          details: 'January income',
          acct_id_dr: bank_account.id,
          debit: 2000.00,
          acct_id_cr: salary_account.id,
          credit: 2000.00
        )

        # February transactions (2 of them)
        Transaction.create!(
          user: user,
          tx_date: Date.new(Date.today.year, 2, 15),
          details: 'February income 1',
          acct_id_dr: bank_account.id,
          debit: 1800.00,
          acct_id_cr: salary_account.id,
          credit: 1800.00
        )

        Transaction.create!(
          user: user,
          tx_date: Date.new(Date.today.year, 2, 28),
          details: 'February income 2',
          acct_id_dr: bank_account.id,
          debit: 200.00,
          acct_id_cr: salary_account.id,
          credit: 200.00
        )

        monthly = salary_account.credits_monthly(Date.today.year)
        
        expect(monthly[1]).to eq(2000.00)
        expect(monthly[2]).to eq(2000.00)  # 1800 + 200
      end

      it 'returns empty hash for year with no transactions' do
        monthly = salary_account.credits_monthly(2000)
        expect(monthly).to be_empty
      end

      it 'defaults to current year when no year specified' do
        Transaction.create!(
          user: user,
          tx_date: Date.today,
          details: 'Current month income',
          acct_id_dr: bank_account.id,
          debit: 3000.00,
          acct_id_cr: salary_account.id,
          credit: 3000.00
        )

        monthly = salary_account.credits_monthly
        expect(monthly[Date.today.month]).to eq(3000.00)
      end

      it 'only includes transactions from specified year' do
        # Transaction in current year
        Transaction.create!(
          user: user,
          tx_date: Date.new(Date.today.year, 6, 15),
          details: 'This year',
          acct_id_dr: bank_account.id,
          debit: 1000.00,
          acct_id_cr: salary_account.id,
          credit: 1000.00
        )

        # Transaction in previous year
        Transaction.create!(
          user: user,
          tx_date: Date.new(Date.today.year - 1, 6, 15),
          details: 'Last year',
          acct_id_dr: bank_account.id,
          debit: 2000.00,
          acct_id_cr: salary_account.id,
          credit: 2000.00
        )

        monthly_this_year = salary_account.credits_monthly(Date.today.year)
        monthly_last_year = salary_account.credits_monthly(Date.today.year - 1)

        expect(monthly_this_year[6]).to eq(1000.00)
        expect(monthly_last_year[6]).to eq(2000.00)
      end
    end

    describe '.debits_yearly(max_years) aggregation' do
      it 'aggregates debits by year correctly' do
        current_year = Date.today.year

        # Create transactions for multiple years
        [0, 1, 2].each do |years_ago|
          Transaction.create!(
            user: user,
            tx_date: Date.new(current_year - years_ago, 6, 15),
            details: "Expense #{years_ago} years ago",
            acct_id_dr: groceries_account.id,
            debit: 1000.00 * (years_ago + 1),
            acct_id_cr: bank_account.id,
            credit: 1000.00 * (years_ago + 1)
          )
        end

        yearly = groceries_account.debits_yearly(10)
        
        expect(yearly[current_year]).to eq(1000.00)
        expect(yearly[current_year - 1]).to eq(2000.00)
        expect(yearly[current_year - 2]).to eq(3000.00)
      end

      it 'respects max_years parameter' do
        current_year = Date.today.year

        # Transaction 2 years ago
        Transaction.create!(
          user: user,
          tx_date: Date.new(current_year - 2, 6, 15),
          details: '2 years ago',
          acct_id_dr: groceries_account.id,
          debit: 100.00,
          acct_id_cr: bank_account.id,
          credit: 100.00
        )

        # Transaction 5 years ago
        Transaction.create!(
          user: user,
          tx_date: Date.new(current_year - 5, 6, 15),
          details: '5 years ago',
          acct_id_dr: groceries_account.id,
          debit: 200.00,
          acct_id_cr: bank_account.id,
          credit: 200.00
        )

        # Transaction 15 years ago (should be excluded)
        Transaction.create!(
          user: user,
          tx_date: Date.new(current_year - 15, 6, 15),
          details: '15 years ago',
          acct_id_dr: groceries_account.id,
          debit: 300.00,
          acct_id_cr: bank_account.id,
          credit: 300.00
        )

        # Default max_years = 10
        yearly = groceries_account.debits_yearly(10)
        
        expect(yearly[current_year - 2]).to eq(100.00)
        expect(yearly[current_year - 5]).to eq(200.00)
        expect(yearly[current_year - 15]).to be_nil  # Should be excluded
      end

      it 'defaults to 10 years when no parameter specified' do
        current_year = Date.today.year

        Transaction.create!(
          user: user,
          tx_date: Date.new(current_year - 3, 1, 1),
          details: '3 years ago',
          acct_id_dr: groceries_account.id,
          debit: 500.00,
          acct_id_cr: bank_account.id,
          credit: 500.00
        )

        yearly = groceries_account.debits_yearly
        expect(yearly[current_year - 3]).to eq(500.00)
      end

      it 'sums multiple transactions in the same year' do
        current_year = Date.today.year

        3.times do |i|
          Transaction.create!(
            user: user,
            tx_date: Date.new(current_year - 1, i + 1, 15),
            details: "Last year transaction #{i+1}",
            acct_id_dr: groceries_account.id,
            debit: 100.00,
            acct_id_cr: bank_account.id,
            credit: 100.00
          )
        end

        yearly = groceries_account.debits_yearly(10)
        expect(yearly[current_year - 1]).to eq(300.00)
      end
    end

    describe '.credits_yearly(max_years) aggregation' do
      it 'aggregates credits by year correctly' do
        current_year = Date.today.year

        # Create transactions for multiple years
        [0, 1, 2].each do |years_ago|
          Transaction.create!(
            user: user,
            tx_date: Date.new(current_year - years_ago, 6, 15),
            details: "Income #{years_ago} years ago",
            acct_id_dr: bank_account.id,
            debit: 20000.00 + (1000.00 * years_ago),
            acct_id_cr: salary_account.id,
            credit: 20000.00 + (1000.00 * years_ago)
          )
        end

        yearly = salary_account.credits_yearly(10)
        
        expect(yearly[current_year]).to eq(20000.00)
        expect(yearly[current_year - 1]).to eq(21000.00)
        expect(yearly[current_year - 2]).to eq(22000.00)
      end

      it 'respects max_years parameter' do
        current_year = Date.today.year

        # Transaction 2 years ago
        Transaction.create!(
          user: user,
          tx_date: Date.new(current_year - 2, 6, 15),
          details: '2 years ago',
          acct_id_dr: bank_account.id,
          debit: 15000.00,
          acct_id_cr: salary_account.id,
          credit: 15000.00
        )

        # Transaction 12 years ago (should be excluded with max_years=10)
        Transaction.create!(
          user: user,
          tx_date: Date.new(current_year - 12, 6, 15),
          details: '12 years ago',
          acct_id_dr: bank_account.id,
          debit: 10000.00,
          acct_id_cr: salary_account.id,
          credit: 10000.00
        )

        # Default max_years = 10
        yearly = salary_account.credits_yearly(10)
        
        expect(yearly[current_year - 2]).to eq(15000.00)
        expect(yearly[current_year - 12]).to be_nil  # Should be excluded
      end

      it 'defaults to 10 years when no parameter specified' do
        current_year = Date.today.year

        Transaction.create!(
          user: user,
          tx_date: Date.new(current_year - 4, 1, 1),
          details: '4 years ago',
          acct_id_dr: bank_account.id,
          debit: 18000.00,
          acct_id_cr: salary_account.id,
          credit: 18000.00
        )

        yearly = salary_account.credits_yearly
        expect(yearly[current_year - 4]).to eq(18000.00)
      end

      it 'sums multiple transactions in the same year' do
        current_year = Date.today.year

        4.times do |i|
          Transaction.create!(
            user: user,
            tx_date: Date.new(current_year - 1, (i * 3) + 1, 15),
            details: "Last year income #{i+1}",
            acct_id_dr: bank_account.id,
            debit: 2000.00,
            acct_id_cr: salary_account.id,
            credit: 2000.00
          )
        end

        yearly = salary_account.credits_yearly(10)
        expect(yearly[current_year - 1]).to eq(8000.00)
      end
    end
  end
end
