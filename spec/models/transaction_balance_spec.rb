require 'spec_helper'

RSpec.describe Transaction, type: :model do
  describe 'Transaction Balance Validation' do
    let(:user) { Fabricate(:user) }
    let(:bank_account) do
      Fabricate(:asset, name: 'Checking Account', user: user)
    end
    let(:groceries_account) do
      Fabricate(:expense, name: 'Groceries', user: user)
    end
    let(:salary_account) do
      Fabricate(:income, name: 'Salary', user: user)
    end
    let(:credit_card_account) do
      Fabricate(:liability, name: 'Visa', user: user)
    end

    describe 'debit equals credit' do
      it 'maintains debit = credit balance for expense transaction' do
        txn = Transaction.create!(
          user: user,
          tx_date: Date.today,
          details: 'Grocery purchase',
          acct_id_dr: groceries_account.id,
          debit: 50.00,
          acct_id_cr: bank_account.id,
          credit: 50.00
        )

        expect(txn.debit).to eq(txn.credit)
        expect(txn.debit).to eq(50.00)
      end

      it 'maintains debit = credit balance for income transaction' do
        txn = Transaction.create!(
          user: user,
          tx_date: Date.today,
          details: 'Salary payment',
          acct_id_dr: bank_account.id,
          debit: 2000.00,
          acct_id_cr: salary_account.id,
          credit: 2000.00
        )

        expect(txn.debit).to eq(txn.credit)
        expect(txn.debit).to eq(2000.00)
      end

      it 'maintains debit = credit balance for transfer (credit card payment)' do
        txn = Transaction.create!(
          user: user,
          tx_date: Date.today,
          details: 'Credit card payment',
          acct_id_dr: credit_card_account.id,
          debit: 500.00,
          acct_id_cr: bank_account.id,
          credit: 500.00
        )

        expect(txn.debit).to eq(txn.credit)
        expect(txn.debit).to eq(500.00)
      end
    end

    describe 'account balance calculations with multiple transactions' do
      it 'correctly sums debits and credits across multiple transactions' do
        # Create 3 expense transactions
        3.times do |i|
          Transaction.create!(
            user: user,
            tx_date: Date.today,
            details: "Expense #{i+1}",
            acct_id_dr: groceries_account.id,
            debit: 25.00 + i,
            acct_id_cr: bank_account.id,
            credit: 25.00 + i
          )
        end

        # Groceries account should have 3 debits: 25 + 26 + 27 = 78
        expect(groceries_account.debits(Date.today.year)).to eq(78.00)

        # Bank account should have 3 credits: 25 + 26 + 27 = 78
        expect(bank_account.credits(Date.today.year)).to eq(78.00)
      end

      it 'correctly calculates net position for asset account' do
        # Income: Bank increases
        Transaction.create!(
          user: user,
          tx_date: Date.today,
          details: 'Salary',
          acct_id_dr: bank_account.id,
          debit: 1000.00,
          acct_id_cr: salary_account.id,
          credit: 1000.00
        )

        # Expense: Bank decreases
        Transaction.create!(
          user: user,
          tx_date: Date.today,
          details: 'Groceries',
          acct_id_dr: groceries_account.id,
          debit: 50.00,
          acct_id_cr: bank_account.id,
          credit: 50.00
        )

        # Bank should have 1000 debit and 50 credit
        # Net position: 950 debit (positive balance)
        expect(bank_account.debits(Date.today.year)).to eq(1000.00)
        expect(bank_account.credits(Date.today.year)).to eq(50.00)
      end

      it 'correctly calculates net position for liability account' do
        # Charge to credit card: Liability increases
        Transaction.create!(
          user: user,
          tx_date: Date.today,
          details: 'Purchase on credit',
          acct_id_dr: groceries_account.id,
          debit: 100.00,
          acct_id_cr: credit_card_account.id,
          credit: 100.00
        )

        # Pay credit card: Liability decreases
        Transaction.create!(
          user: user,
          tx_date: Date.today,
          details: 'Credit card payment',
          acct_id_dr: credit_card_account.id,
          debit: 50.00,
          acct_id_cr: bank_account.id,
          credit: 50.00
        )

        # Credit card should have 100 credit and 50 debit
        # Net position: 50 credit (you owe $50)
        expect(credit_card_account.credits(Date.today.year)).to eq(100.00)
        expect(credit_card_account.debits(Date.today.year)).to eq(50.00)
      end
    end

    describe 'NULL account handling (uncategorized transactions)' do
      it 'allows creating transaction with NULL debit account (uncategorized expense)' do
        txn = Transaction.create!(
          user: user,
          tx_date: Date.today,
          details: 'Imported transaction - uncategorized',
          acct_id_dr: nil,  # Uncategorized - to be filled in later
          debit: 30.00,
          acct_id_cr: bank_account.id,
          credit: 30.00
        )

        expect(txn).to be_valid
        expect(txn.acct_id_dr).to be_nil
        expect(txn.debit).to eq(30.00)
      end

      it 'allows creating transaction with NULL credit account (uncategorized income)' do
        txn = Transaction.create!(
          user: user,
          tx_date: Date.today,
          details: 'Imported transaction - uncategorized income',
          acct_id_dr: bank_account.id,
          debit: 500.00,
          acct_id_cr: nil,  # Uncategorized - to be filled in later
          credit: 500.00
        )

        expect(txn).to be_valid
        expect(txn.acct_id_cr).to be_nil
        expect(txn.credit).to eq(500.00)
      end

      it 'finds uncategorized expenses correctly' do
        # Create uncategorized expense
        Transaction.create!(
          user: user,
          tx_date: Date.today,
          acct_id_dr: nil,
          debit: 30.00,
          acct_id_cr: bank_account.id,
          credit: 30.00
        )

        # Create categorized expense
        Transaction.create!(
          user: user,
          tx_date: Date.today,
          acct_id_dr: groceries_account.id,
          debit: 20.00,
          acct_id_cr: bank_account.id,
          credit: 20.00
        )

        uncategorized = Transaction.uncategorized_expenses(user, Date.today.year)
        # Use .length instead of .count to match production usage
        expect(uncategorized.length).to eq(1)
        expect(uncategorized.first.uncategorized_expenses).to eq(30.00)
        expect(uncategorized.first.count).to eq(1)  # 1 uncategorized transaction
      end

      it 'finds uncategorized revenue correctly' do
        # Create uncategorized income
        Transaction.create!(
          user: user,
          tx_date: Date.today,
          acct_id_dr: bank_account.id,
          debit: 100.00,
          acct_id_cr: nil,
          credit: 100.00
        )

        # Create categorized income
        Transaction.create!(
          user: user,
          tx_date: Date.today,
          acct_id_dr: bank_account.id,
          debit: 200.00,
          acct_id_cr: salary_account.id,
          credit: 200.00
        )

        uncategorized = Transaction.uncategorized_revenue(user, Date.today.year)
        # Use .length instead of .count to match production usage
        expect(uncategorized.length).to eq(1)
        expect(uncategorized.first.uncategorized_revenue).to eq(100.00)
        expect(uncategorized.first.count).to eq(1)  # 1 uncategorized transaction
      end
    end

    describe 'zero amount handling' do
      it 'allows creating transaction with zero amount' do
        txn = Transaction.create!(
          user: user,
          tx_date: Date.today,
          details: 'Zero amount transaction',
          acct_id_dr: groceries_account.id,
          debit: 0.00,
          acct_id_cr: bank_account.id,
          credit: 0.00
        )

        expect(txn).to be_valid
        expect(txn.debit).to eq(0.00)
        expect(txn.credit).to eq(0.00)
      end

      it 'does not include zero amount transactions in account totals' do
        # Create zero amount transaction
        Transaction.create!(
          user: user,
          tx_date: Date.today,
          acct_id_dr: groceries_account.id,
          debit: 0.00,
          acct_id_cr: bank_account.id,
          credit: 0.00
        )

        # Create real transaction
        Transaction.create!(
          user: user,
          tx_date: Date.today,
          acct_id_dr: groceries_account.id,
          debit: 25.00,
          acct_id_cr: bank_account.id,
          credit: 25.00
        )

        # Should only sum non-zero transactions
        expect(groceries_account.debits(Date.today.year)).to eq(25.00)
      end
    end

    describe 'negative amount handling' do
      it 'allows creating transaction with negative amounts (refund scenario)' do
        # Negative amounts might represent refunds or corrections
        txn = Transaction.create!(
          user: user,
          tx_date: Date.today,
          details: 'Refund or correction',
          acct_id_dr: groceries_account.id,
          debit: -10.00,
          acct_id_cr: bank_account.id,
          credit: -10.00
        )

        expect(txn).to be_valid
        expect(txn.debit).to eq(-10.00)
        expect(txn.credit).to eq(-10.00)
      end

      it 'correctly calculates account totals with negative amounts' do
        # Regular expense
        Transaction.create!(
          user: user,
          tx_date: Date.today,
          acct_id_dr: groceries_account.id,
          debit: 100.00,
          acct_id_cr: bank_account.id,
          credit: 100.00
        )

        # Refund (negative)
        Transaction.create!(
          user: user,
          tx_date: Date.today,
          acct_id_dr: groceries_account.id,
          debit: -10.00,
          acct_id_cr: bank_account.id,
          credit: -10.00
        )

        # Net: 100 - 10 = 90
        expect(groceries_account.debits(Date.today.year)).to eq(90.00)
        expect(bank_account.credits(Date.today.year)).to eq(90.00)
      end
    end
  end
end
