require 'spec_helper'

RSpec.feature 'CSV Import', type: :feature do
  let(:user) { Fabricate(:user) }
  let(:rbc_visa_account) do
    Fabricate(:liability, name: 'RBC Visa', import_class: 'RBC Visa', user: user)
  end
  let(:vancity_account) do
    Fabricate(:asset, name: 'Vancity Chequing', import_class: 'Vancity', user: user)
  end

  before do
    login_user(user, user.password)
  end

  describe 'Successful CSV import' do
    it 'creates transactions from RBC Visa CSV file' do
      # Ensure account exists
      rbc_visa_account

      # Create file upload
      file_path = Rails.root.join('spec', 'fixtures', 'csv', 'rbc_visa_sample.csv')

      visit '/transaction_imports/new'

      select 'RBC Visa', from: 'transaction_import_account_id'
      attach_file 'transaction_import_file', file_path
      click_button 'Import'

      expect(page).to have_text('Transactions imported successfully')

      # Verify transactions were created
      expect(Transaction.count).to eq(3)

      # Verify transaction details
      grocery_txn = Transaction.find_by(details: 'GROCERY STORE')
      expect(grocery_txn).not_to be_nil
      expect(grocery_txn.credit).to eq(50.00)
      expect(grocery_txn.debit).to be_nil

      gas_txn = Transaction.find_by(details: 'GAS STATION')
      expect(gas_txn).not_to be_nil
      expect(gas_txn.credit).to eq(75.50)

      payment_txn = Transaction.find_by_details('PAYMENT - THANK YOU / PAIEMENT - MERCI')
      expect(payment_txn).not_to be_nil
      expect(payment_txn.debit).to eq(1000.00)
      expect(payment_txn.credit).to be_nil
    end

    it 'creates transactions from Vancity CSV file' do
      # Ensure account exists
      vancity_account

      file_path = Rails.root.join('spec', 'fixtures', 'csv', 'vancity_sample.csv')

      visit '/transaction_imports/new'

      select 'Vancity Chequing', from: 'transaction_import_account_id'
      attach_file 'transaction_import_file', file_path
      click_button 'Import'

      expect(page).to have_text('Transactions imported successfully')

      # Verify transactions were created
      expect(Transaction.count).to eq(3)

      # Verify a specific transaction
      # For a bank account (asset), deposits are debits (increase asset)
      salary_txn = Transaction.find_by_details('SALARY')
      expect(salary_txn).not_to be_nil
      expect(salary_txn.debit).to eq(2000.00)
    end
  end

  describe 'Uncategorized transactions' do
    it 'imports expense transactions with NULL debit account (uncategorized)' do
      rbc_visa_account

      file_path = Rails.root.join('spec', 'fixtures', 'csv', 'rbc_visa_sample.csv')

      visit '/transaction_imports/new'
      select 'RBC Visa', from: 'transaction_import_account_id'
      attach_file 'transaction_import_file', file_path
      click_button 'Import'

      # Check that expense transactions (charges) have NULL debit account
      grocery_txn = Transaction.find_by(details: 'GROCERY STORE')
      expect(grocery_txn.acct_id_cr).to eq(rbc_visa_account.id)  # Credit card is credited
      expect(grocery_txn.acct_id_dr).to be_nil  # Expense category is NULL (uncategorized)
      expect(grocery_txn.credit).to eq(50.00)
      expect(grocery_txn.debit).to be_nil
    end

    it 'imports payment transactions with NULL credit account (uncategorized)' do
      rbc_visa_account

      file_path = Rails.root.join('spec', 'fixtures', 'csv', 'rbc_visa_sample.csv')

      visit '/transaction_imports/new'
      select 'RBC Visa', from: 'transaction_import_account_id'
      attach_file 'transaction_import_file', file_path
      click_button 'Import'

      # Check that payment transactions have NULL credit account
      payment_txn = Transaction.find_by_details('PAYMENT - THANK YOU / PAIEMENT - MERCI')
      expect(payment_txn.acct_id_dr).to eq(rbc_visa_account.id)  # Credit card is debited (payment reduces liability)
      expect(payment_txn.acct_id_cr).to be_nil  # Bank account is NULL (uncategorized)
      expect(payment_txn.debit).to eq(1000.00)
      expect(payment_txn.credit).to be_nil
    end

    it 'shows uncategorized transactions can be found using query methods' do
      rbc_visa_account

      file_path = Rails.root.join('spec', 'fixtures', 'csv', 'rbc_visa_sample.csv')

      visit '/transaction_imports/new'
      select 'RBC Visa', from: 'transaction_import_account_id'
      attach_file 'transaction_import_file', file_path
      click_button 'Import'

      # Verify uncategorized expenses can be found
      # Use 2024 since that's the year in the CSV fixture
      uncategorized_expenses = Transaction.uncategorized_expenses(user, 2024)
      expect(uncategorized_expenses.length).to eq(1)
      expect(uncategorized_expenses.first.uncategorized_expenses).to eq(125.50)  # 50 + 75.50

      # Verify uncategorized revenue can be found (the payment is uncategorized on credit side)
      uncategorized_revenue = Transaction.uncategorized_revenue(user, 2024)
      expect(uncategorized_revenue.length).to eq(1)
      expect(uncategorized_revenue.first.uncategorized_revenue).to eq(1000.00)
    end
  end

  describe 'Duplicate detection' do
    it 'prevents re-importing the same transaction twice' do
      rbc_visa_account

      file_path = Rails.root.join('spec', 'fixtures', 'csv', 'rbc_visa_duplicates.csv')

      visit '/transaction_imports/new'
      select 'RBC Visa', from: 'transaction_import_account_id'
      attach_file 'transaction_import_file', file_path
      click_button 'Import'

      # Should only create 1 transaction, not 2
      # The second identical line should be rejected due to tx_hash uniqueness constraint
      expect(Transaction.count).to eq(1)

      grocery_txn = Transaction.find_by(details: 'GROCERY STORE')
      expect(grocery_txn).not_to be_nil
    end

    it 'does not re-import transactions from a previously imported file' do
      rbc_visa_account

      file_path = Rails.root.join('spec', 'fixtures', 'csv', 'rbc_visa_sample.csv')

      # First import
      visit '/transaction_imports/new'
      select 'RBC Visa', from: 'transaction_import_account_id'
      attach_file 'transaction_import_file', file_path
      click_button 'Import'

      expect(Transaction.count).to eq(3)

      # Second import of same file
      visit '/transaction_imports/new'
      select 'RBC Visa', from: 'transaction_import_account_id'
      attach_file 'transaction_import_file', file_path
      click_button 'Import'

      # Should still only have 3 transactions, not 6
      expect(Transaction.count).to eq(3)
    end
  end

  describe 'Import assigns correct bank account' do
    it 'assigns imported transactions to the selected account' do
      rbc_visa_account
      vancity_account

      file_path = Rails.root.join('spec', 'fixtures', 'csv', 'rbc_visa_sample.csv')

      visit '/transaction_imports/new'

      # Import to RBC Visa account
      select 'RBC Visa', from: 'transaction_import_account_id'
      attach_file 'transaction_import_file', file_path
      click_button 'Import'

      # All transactions should reference the RBC Visa account
      Transaction.all.each do |txn|
        # For liability account (credit card), either acct_id_dr or acct_id_cr should be the account
        expect([txn.acct_id_dr, txn.acct_id_cr]).to include(rbc_visa_account.id)
      end
    end
  end

  describe 'Error handling' do
    it 'displays error message when no account is selected' do
      file_path = Rails.root.join('spec', 'fixtures', 'csv', 'rbc_visa_sample.csv')

      visit '/transaction_imports/new'

      # Don't select an account
      attach_file 'transaction_import_file', file_path
      click_button 'Import'

      expect(page).to have_text('Please select an account')
      expect(Transaction.count).to eq(0)
    end

    it 'displays error message when no file is selected' do
      rbc_visa_account

      visit '/transaction_imports/new'

      select 'RBC Visa', from: 'transaction_import_account_id'
      # Don't attach a file
      click_button 'Import'

      expect(page).to have_text('Please select a file')
      expect(Transaction.count).to eq(0)
    end

    it 'handles malformed CSV gracefully' do
      rbc_visa_account

      file_path = Rails.root.join('spec', 'fixtures', 'csv', 'malformed.csv')

      visit '/transaction_imports/new'
      select 'RBC Visa', from: 'transaction_import_account_id'
      attach_file 'transaction_import_file', file_path
      click_button 'Import'

      # Should show errors but not crash
      expect(page).to have_text('Row')  # Error message contains row number

      # Should not create invalid transactions
      # Might create 0 transactions depending on error handling
      expect(Transaction.count).to be <= 1
    end
  end

  describe 'Transaction hash generation' do
    it 'generates unique tx_hash for each transaction' do
      rbc_visa_account

      file_path = Rails.root.join('spec', 'fixtures', 'csv', 'rbc_visa_sample.csv')

      visit '/transaction_imports/new'
      select 'RBC Visa', from: 'transaction_import_account_id'
      attach_file 'transaction_import_file', file_path
      click_button 'Import'

      # All transactions should have a tx_hash
      Transaction.all.each do |txn|
        expect(txn.tx_hash).not_to be_nil
        expect(txn.tx_hash).not_to be_empty
      end

      # All hashes should be unique
      hashes = Transaction.pluck(:tx_hash)
      expect(hashes.uniq.length).to eq(hashes.length)
    end
  end
end
