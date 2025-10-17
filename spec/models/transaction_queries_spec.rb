require 'spec_helper'

RSpec.describe Transaction, type: :model do
  describe 'Transaction Query Methods' do
    let(:user) { Fabricate(:user) }

    # Asset accounts
    let(:checking_account) do
      account = Fabricate(:asset, name: 'Checking Account', import_class: 'BankImporter')
      user.accounts << account unless user.accounts.include?(account)
      account
    end

    let(:savings_account) do
      account = Fabricate(:asset, name: 'Savings Account')
      user.accounts << account unless user.accounts.include?(account)
      account
    end

    # Liability accounts
    let(:visa_account) do
      account = Fabricate(:liability, name: 'Visa Card', import_class: 'VisaImporter')
      user.accounts << account unless user.accounts.include?(account)
      account
    end

    # Income accounts
    let(:salary_account) do
      account = Fabricate(:income, name: 'Salary')
      user.accounts << account unless user.accounts.include?(account)
      account
    end

    let(:interest_account) do
      account = Fabricate(:income, name: 'Interest Income')
      user.accounts << account unless user.accounts.include?(account)
      account
    end

    # Expense accounts
    let(:groceries_account) do
      account = Fabricate(:expense, name: 'Groceries')
      user.accounts << account unless user.accounts.include?(account)
      account
    end

    let(:rent_account) do
      account = Fabricate(:expense, name: 'Rent')
      user.accounts << account unless user.accounts.include?(account)
      account
    end

    let(:utilities_account) do
      account = Fabricate(:expense, name: 'Utilities')
      user.accounts << account unless user.accounts.include?(account)
      account
    end

    describe '.income_by_category' do
      it 'aggregates income transactions by income account' do
        # Create income from salary
        Transaction.create!(
          user: user,
          tx_date: Date.new(2024, 1, 15),
          details: 'Salary payment',
          acct_id_dr: checking_account.id,
          debit: 5000.00,
          acct_id_cr: salary_account.id,
          credit: 5000.00
        )

        # Create income from interest
        Transaction.create!(
          user: user,
          tx_date: Date.new(2024, 1, 20),
          details: 'Interest payment',
          acct_id_dr: savings_account.id,
          debit: 100.00,
          acct_id_cr: interest_account.id,
          credit: 100.00
        )

        results = Transaction.income_by_category(user, 2024, 1)

        expect(results.length).to eq(2)

        salary_result = results.find { |r| r.name == 'Salary' }
        expect(salary_result.income).to eq(5000.00)

        interest_result = results.find { |r| r.name == 'Interest Income' }
        expect(interest_result.income).to eq(100.00)
      end

      it 'aggregates across multiple months when month is nil' do
        # January salary
        Transaction.create!(
          user: user,
          tx_date: Date.new(2024, 1, 15),
          details: 'Salary',
          acct_id_dr: checking_account.id,
          debit: 5000.00,
          acct_id_cr: salary_account.id,
          credit: 5000.00
        )

        # February salary
        Transaction.create!(
          user: user,
          tx_date: Date.new(2024, 2, 15),
          details: 'Salary',
          acct_id_dr: checking_account.id,
          debit: 5000.00,
          acct_id_cr: salary_account.id,
          credit: 5000.00
        )

        results = Transaction.income_by_category(user, 2024, nil)

        # Should have 2 results (one per month) for Salary
        expect(results.length).to eq(2)
        expect(results.sum { |r| r.income }).to eq(10000.00)
      end
    end

    describe '.expenses_by_category' do
      it 'aggregates expense transactions by expense account' do
        # Groceries expense
        Transaction.create!(
          user: user,
          tx_date: Date.new(2024, 1, 10),
          details: 'Grocery shopping',
          acct_id_dr: groceries_account.id,
          debit: 150.00,
          acct_id_cr: checking_account.id,
          credit: 150.00
        )

        # Rent expense
        Transaction.create!(
          user: user,
          tx_date: Date.new(2024, 1, 1),
          details: 'Monthly rent',
          acct_id_dr: rent_account.id,
          debit: 2000.00,
          acct_id_cr: checking_account.id,
          credit: 2000.00
        )

        results = Transaction.expenses_by_category(user, 2024, 1)

        expect(results.length).to eq(2)

        groceries_result = results.find { |r| r.name == 'Groceries' }
        expect(groceries_result.expenses).to eq(150.00)

        rent_result = results.find { |r| r.name == 'Rent' }
        expect(rent_result.expenses).to eq(2000.00)
      end

      it 'handles expenses from both asset and liability accounts' do
        # Expense paid from checking (asset)
        Transaction.create!(
          user: user,
          tx_date: Date.new(2024, 1, 10),
          details: 'Groceries - cash',
          acct_id_dr: groceries_account.id,
          debit: 100.00,
          acct_id_cr: checking_account.id,
          credit: 100.00
        )

        # Expense paid by credit card (liability)
        Transaction.create!(
          user: user,
          tx_date: Date.new(2024, 1, 15),
          details: 'Groceries - credit',
          acct_id_dr: groceries_account.id,
          debit: 50.00,
          acct_id_cr: visa_account.id,
          credit: 50.00
        )

        results = Transaction.expenses_by_category(user, 2024, 1)

        groceries_result = results.find { |r| r.name == 'Groceries' }
        expect(groceries_result.expenses).to eq(150.00)
      end
    end

    describe '.income_by_account' do
      it 'aggregates income by asset account that received the income' do
        # Income to checking
        Transaction.create!(
          user: user,
          tx_date: Date.new(2024, 1, 15),
          details: 'Salary to checking',
          acct_id_dr: checking_account.id,
          debit: 5000.00,
          acct_id_cr: salary_account.id,
          credit: 5000.00
        )

        # Income to savings
        Transaction.create!(
          user: user,
          tx_date: Date.new(2024, 1, 20),
          details: 'Interest to savings',
          acct_id_dr: savings_account.id,
          debit: 100.00,
          acct_id_cr: interest_account.id,
          credit: 100.00
        )

        results = Transaction.income_by_account(user, 2024, 1)

        expect(results.length).to eq(2)

        checking_result = results.find { |r| r.name == 'Checking Account' }
        expect(checking_result.credit).to eq(5000.00)

        savings_result = results.find { |r| r.name == 'Savings Account' }
        expect(savings_result.credit).to eq(100.00)
      end
    end

    describe '.cash_spend_by_account' do
      it 'aggregates spending from asset accounts with import_class' do
        # Spending from checking (has import_class)
        Transaction.create!(
          user: user,
          tx_date: Date.new(2024, 1, 10),
          details: 'Groceries',
          acct_id_dr: groceries_account.id,
          debit: 150.00,
          acct_id_cr: checking_account.id,
          credit: 150.00
        )

        Transaction.create!(
          user: user,
          tx_date: Date.new(2024, 1, 15),
          details: 'Rent',
          acct_id_dr: rent_account.id,
          debit: 2000.00,
          acct_id_cr: checking_account.id,
          credit: 2000.00
        )

        results = Transaction.cash_spend_by_account(user, 2024, 1)

        expect(results.length).to eq(1)
        expect(results.first.name).to eq('Checking Account')
        expect(results.first.credit).to eq(2150.00)
      end

      it 'excludes spending from asset accounts without import_class' do
        # Spending from savings (no import_class)
        Transaction.create!(
          user: user,
          tx_date: Date.new(2024, 1, 10),
          details: 'Transfer',
          acct_id_dr: utilities_account.id,
          debit: 100.00,
          acct_id_cr: savings_account.id,
          credit: 100.00
        )

        results = Transaction.cash_spend_by_account(user, 2024, 1)

        # Should be empty because savings doesn't have import_class
        expect(results.length).to eq(0)
      end
    end

    describe '.credit_spend_by_account' do
      it 'aggregates spending from liability accounts with import_class' do
        # Spending on credit card
        Transaction.create!(
          user: user,
          tx_date: Date.new(2024, 1, 10),
          details: 'Groceries on credit',
          acct_id_dr: groceries_account.id,
          debit: 150.00,
          acct_id_cr: visa_account.id,
          credit: 150.00
        )

        Transaction.create!(
          user: user,
          tx_date: Date.new(2024, 1, 15),
          details: 'Utilities on credit',
          acct_id_dr: utilities_account.id,
          debit: 75.00,
          acct_id_cr: visa_account.id,
          credit: 75.00
        )

        results = Transaction.credit_spend_by_account(user, 2024, 1)

        expect(results.length).to eq(1)
        expect(results.first.name).to eq('Visa Card')
        expect(results.first.credit).to eq(225.00)
      end
    end

    describe '.expenses_all_time' do
      it 'aggregates expenses by year across all years' do
        # 2023 expenses
        Transaction.create!(
          user: user,
          tx_date: Date.new(2023, 6, 10),
          details: 'Groceries 2023',
          acct_id_dr: groceries_account.id,
          debit: 1000.00,
          acct_id_cr: checking_account.id,
          credit: 1000.00
        )

        # 2024 expenses
        Transaction.create!(
          user: user,
          tx_date: Date.new(2024, 6, 10),
          details: 'Groceries 2024',
          acct_id_dr: groceries_account.id,
          debit: 1500.00,
          acct_id_cr: checking_account.id,
          credit: 1500.00
        )

        results = Transaction.expenses_all_time(user)

        expect(results.length).to eq(2)

        result_2023 = results.find { |r| r.year == 2023 }
        expect(result_2023.expenses).to eq(1000.00)

        result_2024 = results.find { |r| r.year == 2024 }
        expect(result_2024.expenses).to eq(1500.00)
      end

      it 'filters by specific year when provided' do
        # 2023 expenses
        Transaction.create!(
          user: user,
          tx_date: Date.new(2023, 6, 10),
          details: 'Groceries 2023',
          acct_id_dr: groceries_account.id,
          debit: 1000.00,
          acct_id_cr: checking_account.id,
          credit: 1000.00
        )

        # 2024 expenses
        Transaction.create!(
          user: user,
          tx_date: Date.new(2024, 6, 10),
          details: 'Groceries 2024',
          acct_id_dr: groceries_account.id,
          debit: 1500.00,
          acct_id_cr: checking_account.id,
          credit: 1500.00
        )

        results = Transaction.expenses_all_time(user, 2024)

        expect(results.length).to eq(1)
        expect(results.first.year).to eq(2024)
        expect(results.first.expenses).to eq(1500.00)
      end
    end

    describe '.expenses_by_spending_account' do
      it 'shows expenses broken down by which account was used to pay' do
        # Expenses from checking
        Transaction.create!(
          user: user,
          tx_date: Date.new(2024, 1, 10),
          details: 'Groceries - checking',
          acct_id_dr: groceries_account.id,
          debit: 100.00,
          acct_id_cr: checking_account.id,
          credit: 100.00
        )

        # Expenses from credit card
        Transaction.create!(
          user: user,
          tx_date: Date.new(2024, 1, 15),
          details: 'Rent - credit',
          acct_id_dr: rent_account.id,
          debit: 2000.00,
          acct_id_cr: visa_account.id,
          credit: 2000.00
        )

        results = Transaction.expenses_by_spending_account(user, 2024)

        expect(results.length).to eq(2)

        checking_result = results.find { |r| r.account == 'Checking Account' }
        expect(checking_result.expenses).to eq(100.00)

        visa_result = results.find { |r| r.account == 'Visa Card' }
        expect(visa_result.expenses).to eq(2000.00)
      end

      it 'only includes accounts with import_class' do
        # Expense from savings (no import_class)
        Transaction.create!(
          user: user,
          tx_date: Date.new(2024, 1, 10),
          details: 'Transfer',
          acct_id_dr: utilities_account.id,
          debit: 100.00,
          acct_id_cr: savings_account.id,
          credit: 100.00
        )

        results = Transaction.expenses_by_spending_account(user, 2024)

        # Should not include savings account result
        expect(results.any? { |r| r.account == 'Savings Account' }).to be false
      end
    end

    describe '.revenues_all_time' do
      it 'aggregates revenue by year across all years' do
        # 2023 revenue
        Transaction.create!(
          user: user,
          tx_date: Date.new(2023, 6, 15),
          details: 'Salary 2023',
          acct_id_dr: checking_account.id,
          debit: 50000.00,
          acct_id_cr: salary_account.id,
          credit: 50000.00
        )

        # 2024 revenue
        Transaction.create!(
          user: user,
          tx_date: Date.new(2024, 6, 15),
          details: 'Salary 2024',
          acct_id_dr: checking_account.id,
          debit: 60000.00,
          acct_id_cr: salary_account.id,
          credit: 60000.00
        )

        results = Transaction.revenues_all_time(user)

        expect(results.length).to eq(2)

        result_2023 = results.find { |r| r.year == 2023 }
        expect(result_2023.revenue).to eq(50000.00)

        result_2024 = results.find { |r| r.year == 2024 }
        expect(result_2024.revenue).to eq(60000.00)
      end

      it 'filters by specific year when provided' do
        # 2023 revenue
        Transaction.create!(
          user: user,
          tx_date: Date.new(2023, 6, 15),
          details: 'Salary 2023',
          acct_id_dr: checking_account.id,
          debit: 50000.00,
          acct_id_cr: salary_account.id,
          credit: 50000.00
        )

        # 2024 revenue
        Transaction.create!(
          user: user,
          tx_date: Date.new(2024, 6, 15),
          details: 'Salary 2024',
          acct_id_dr: checking_account.id,
          debit: 60000.00,
          acct_id_cr: salary_account.id,
          credit: 60000.00
        )

        results = Transaction.revenues_all_time(user, 2024)

        expect(results.length).to eq(1)
        expect(results.first.year).to eq(2024)
        expect(results.first.revenue).to eq(60000.00)
      end
    end
  end
end
