# Plan: Refactor to Proper Double-Entry Transaction Model

**Date**: 2025-10-17
**Status**: Planning

## Overview
Transform the current hybrid transaction structure into a proper double-entry bookkeeping system where each transaction is a container with multiple entries, and each entry belongs to one account with either a debit or credit (never both).

## Current Problems

The existing `transactions` table has a hybrid structure that doesn't properly implement double-entry bookkeeping:
- Has BOTH `debit` and `credit` columns
- Has `acct_id_dr` and `acct_id_cr` for account references
- This limits every transaction to exactly 2 accounts (one debit, one credit)
- Can't handle multi-leg transactions (e.g., splitting a restaurant expense between "Meals" and "Entertainment")
- Creates "SQL gymnastics" throughout the codebase with complex queries

## Proposed Database Schema

### New Structure
```
transactions (container)
├── id
├── user_id
├── tx_date
├── posting_date
├── description (renamed from 'details')
├── notes
├── tx_hash
├── parent_id (for split transactions)
└── timestamps

transaction_entries (the actual debits and credits)
├── id
├── transaction_id (foreign key)
├── account_id (foreign key)
├── debit_amount (decimal, nullable)
├── credit_amount (decimal, nullable)
├── memo (optional note for this specific entry)
└── timestamps

Constraint: For each transaction_id, SUM(debit_amount) MUST equal SUM(credit_amount)
```

### Key Principles
- **Transactions** are containers that group related entries
- **TransactionEntries** are the actual debits and credits
- Each entry affects ONE account only
- Each entry has EITHER a debit OR a credit (never both)
- Debits must equal credits for each transaction (enforced at DB level)

### Handling Uncategorized Imports (Suspense Account Pattern)

**Problem**: When importing bank statements, you know one side of the transaction (the bank account) but often don't know the category until later (e.g., a $30 debit that you later identify as "Groceries").

**Solution**: Use **Suspense Accounts** (standard accounting practice) to keep transactions balanced while categorization is pending.

#### Suspense Accounts to Create:
```ruby
Account.create!(
  name: 'Uncategorized Expenses',
  account_type: 'Expense',
  description: 'Temporary holding account for imported transactions (money leaving) awaiting categorization. Can be recategorized as Expense, Asset transfer, or Liability payment.'
)

Account.create!(
  name: 'Uncategorized Income',
  account_type: 'Income',
  description: 'Temporary holding account for imported transactions (money entering) awaiting categorization. Can be recategorized as Income, Asset transfer, or Liability.'
)
```

**Note**: Despite the names "Uncategorized Expenses" and "Uncategorized Income", these suspense accounts can be recategorized to ANY account type:
- **Expense/Income** → True expense or income (affects Income Statement)
- **Asset** → Transfer between asset accounts (e.g., checking → savings)
- **Liability** → Debt payment or loan (e.g., credit card payment reduces liability)

#### Import Workflow:

**Step 1: On CSV Import** (before categorization)
```ruby
# Bank statement shows: $30 spent at "Store XYZ"
Transaction.create!(
  tx_date: Date.parse('2025-10-17'),
  description: 'Store XYZ',
  entries_attributes: [
    { account_id: bank_account.id, credit_amount: 30.00 },              # Bank balance decreases
    { account_id: uncategorized_expenses_account.id, debit_amount: 30.00 }  # Temporarily to suspense
  ]
)
```

**Step 2: After Categorization** (user identifies the correct account)

**Example A: Categorize as Expense (Groceries)**
```ruby
suspense_entry = transaction.entries.find_by(account: uncategorized_expenses_account)
suspense_entry.update!(account_id: groceries_account.id)

# Result: Debit Groceries (Expense), Credit Bank (Asset)
# Effect: Expense on income statement
```

**Example B: Categorize as Transfer (Credit Card Payment)**
```ruby
suspense_entry = transaction.entries.find_by(account: uncategorized_expenses_account)
suspense_entry.update!(account_id: visa_credit_card_account.id)

# Result: Debit Visa Credit Card (Liability), Credit Bank (Asset)
# Effect: Both balance sheet accounts reduced, NO income statement impact
```

**Example C: Categorize as Transfer (Moving to Savings)**
```ruby
suspense_entry = transaction.entries.find_by(account: uncategorized_expenses_account)
suspense_entry.update!(account_id: savings_account.id)

# Result: Debit Savings Account (Asset), Credit Bank (Asset)
# Effect: Asset-to-asset transfer, NO income statement impact
```

#### Benefits:
- ✅ Transactions are **always balanced** (proper double-entry)
- ✅ Can import immediately without knowing category
- ✅ Clear audit trail (can see what's uncategorized)
- ✅ Reports show "Amount in Suspense" as data quality metric
- ✅ Balance sheet always balances
- ✅ Standard accounting practice
- ✅ Handles ALL transaction types: expenses, income, transfers, and debt payments

#### Transaction Type Reference

**After categorization, the system correctly handles all transaction types:**

| Import Shows | Categorize As | Account Types | Result | Income Statement Impact |
|--------------|---------------|---------------|---------|-------------------------|
| $30 spent | Groceries (Expense) | Debit Expense, Credit Asset | Expense recorded | ✅ Reduces profit |
| $30 spent | Visa (Liability) | Debit Liability, Credit Asset | Debt payment | ❌ No impact |
| $30 spent | Savings (Asset) | Debit Asset, Credit Asset | Asset transfer | ❌ No impact |
| $2000 received | Salary (Income) | Debit Asset, Credit Income | Income recorded | ✅ Increases profit |
| $2000 received | Savings (Asset) | Debit Asset, Credit Asset | Asset transfer | ❌ No impact |
| $2000 received | Credit Card (Liability) | Debit Asset, Credit Liability | Taking on debt | ❌ No impact |

**Key Insight**: The suspense account approach works universally. When you categorize, you're simply choosing the correct account type, and double-entry bookkeeping automatically produces the right financial statement impact.

## Implementation Steps

### 1. Create New Schema (Migration)
- Generate migration to create `transaction_entries` table
- Add database constraint to validate debit/credit balance
- Keep old columns temporarily for data migration
- Add index on `transaction_id` and `account_id` for performance
- Add foreign key constraints with proper CASCADE behavior

**Migration file structure:**
```ruby
class CreateTransactionEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :transaction_entries do |t|
      t.references :transaction, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.decimal :debit_amount, precision: 12, scale: 2
      t.decimal :credit_amount, precision: 12, scale: 2
      t.text :memo

      t.timestamps

      # Ensure exactly one of debit or credit is present
      t.check_constraint "
        (debit_amount IS NOT NULL AND credit_amount IS NULL) OR
        (debit_amount IS NULL AND credit_amount IS NOT NULL)
      ", name: 'one_amount_required'

      # Ensure amounts are positive
      t.check_constraint "debit_amount IS NULL OR debit_amount >= 0", name: 'debit_non_negative'
      t.check_constraint "credit_amount IS NULL OR credit_amount >= 0", name: 'credit_non_negative'
    end

    add_index :transaction_entries, [:transaction_id, :account_id]
  end
end
```

### 2. Data Migration Strategy

**Phase 1: Create Suspense Accounts**
```ruby
uncategorized_expense = Account.find_or_create_by!(
  name: 'Uncategorized Expenses',
  account_type: 'Expense',
  description: 'Temporary holding account for imported expenses awaiting categorization'
)

uncategorized_income = Account.find_or_create_by!(
  name: 'Uncategorized Income',
  account_type: 'Income',
  description: 'Temporary holding account for imported income awaiting categorization'
)
```

**Phase 2: Analyze existing data**
```ruby
# Count transactions with NULL accounts
null_dr_count = Transaction.where(acct_id_dr: nil).count
null_cr_count = Transaction.where(acct_id_cr: nil).count
puts "Transactions with NULL debit account: #{null_dr_count}"
puts "Transactions with NULL credit account: #{null_cr_count}"

# Identify transactions with zero amounts
zero_amounts = Transaction.where('debit = 0 OR credit = 0 OR debit IS NULL OR credit IS NULL').count
puts "Transactions with zero/NULL amounts: #{zero_amounts}"

# Find any anomalies that need manual review
unbalanced = Transaction.where('debit != credit').count
puts "Unbalanced transactions: #{unbalanced}"
```

**Phase 3: Convert existing transactions**
```ruby
Transaction.find_each do |txn|
  # Create debit entry if present
  if txn.acct_id_dr.present? && txn.debit.present? && txn.debit > 0
    TransactionEntry.create!(
      transaction_id: txn.id,
      account_id: txn.acct_id_dr,
      debit_amount: txn.debit,
      memo: nil
    )
  elsif txn.debit.present? && txn.debit > 0
    # NULL debit account - use suspense account
    # This happens when user imported but hasn't categorized yet
    TransactionEntry.create!(
      transaction_id: txn.id,
      account_id: uncategorized_expense.id,  # Assume expense for now
      debit_amount: txn.debit,
      memo: 'Migrated from uncategorized transaction'
    )
  end

  # Create credit entry if present
  if txn.acct_id_cr.present? && txn.credit.present? && txn.credit > 0
    TransactionEntry.create!(
      transaction_id: txn.id,
      account_id: txn.acct_id_cr,
      credit_amount: txn.credit,
      memo: nil
    )
  elsif txn.credit.present? && txn.credit > 0
    # NULL credit account - use suspense account
    # This happens when user imported but hasn't categorized yet
    TransactionEntry.create!(
      transaction_id: txn.id,
      account_id: uncategorized_income.id,  # Assume income for now
      credit_amount: txn.credit,
      memo: 'Migrated from uncategorized transaction'
    )
  end
end
```

**Phase 3: Validate migration**
- Ensure every transaction has balanced entries
- Verify total debits = total credits across all transactions
- Compare account balances before/after migration
- Test a sample of transactions manually

**Phase 4: Add rollback capability**
- Create down migration that can restore old structure
- Backup database before running migration

### 3. Update Models

**Transaction model updates:**
```ruby
class Transaction < ApplicationRecord
  has_many :entries, class_name: 'TransactionEntry', dependent: :destroy
  has_many :accounts, through: :entries

  accepts_nested_attributes_for :entries, allow_destroy: true

  validates_presence_of :tx_date
  validate :debits_equal_credits
  validate :minimum_two_entries

  # Helper methods
  def total_amount
    entries.sum { |e| e.debit_amount || e.credit_amount || 0 }
  end

  def debit_entries
    entries.where.not(debit_amount: nil)
  end

  def credit_entries
    entries.where.not(credit_amount: nil)
  end

  def total_debits
    entries.sum(:debit_amount)
  end

  def total_credits
    entries.sum(:credit_amount)
  end

  def balanced?
    total_debits == total_credits
  end

  def uncategorized?
    entries.joins(:account).where(
      accounts: { name: ['Uncategorized Expenses', 'Uncategorized Income'] }
    ).exists?
  end

  def uncategorized_entries
    entries.joins(:account).where(
      accounts: { name: ['Uncategorized Expenses', 'Uncategorized Income'] }
    )
  end

  # Scopes
  scope :uncategorized, -> {
    joins(entries: :account).where(
      accounts: { name: ['Uncategorized Expenses', 'Uncategorized Income'] }
    ).distinct
  }

  private

  def debits_equal_credits
    unless balanced?
      errors.add(:base, "Debits (#{total_debits}) must equal credits (#{total_credits})")
    end
  end

  def minimum_two_entries
    if entries.size < 2
      errors.add(:base, "Transaction must have at least 2 entries (one debit and one credit)")
    end
  end
end
```

**Create TransactionEntry model:**
```ruby
class TransactionEntry < ApplicationRecord
  belongs_to :transaction
  belongs_to :account

  validates_presence_of :transaction, :account
  validate :exactly_one_amount
  validate :amount_positive
  validate :normal_balance_check

  scope :debits, -> { where.not(debit_amount: nil) }
  scope :credits, -> { where.not(credit_amount: nil) }

  def amount
    debit_amount || credit_amount
  end

  def debit?
    debit_amount.present?
  end

  def credit?
    credit_amount.present?
  end

  private

  def exactly_one_amount
    if debit_amount.present? && credit_amount.present?
      errors.add(:base, "Entry cannot have both debit and credit")
    elsif debit_amount.blank? && credit_amount.blank?
      errors.add(:base, "Entry must have either debit or credit")
    end
  end

  def amount_positive
    if debit_amount.present? && debit_amount < 0
      errors.add(:debit_amount, "must be positive")
    end
    if credit_amount.present? && credit_amount < 0
      errors.add(:credit_amount, "must be positive")
    end
  end

  def normal_balance_check
    return unless account

    # Warning only - don't prevent but flag unusual entries
    if account.asset? || account.expense?
      if credit_amount.present?
        # Credits to assets/expenses reduce them (e.g., refunds) - valid but uncommon
      end
    elsif account.liability? || account.equity? || account.income?
      if debit_amount.present?
        # Debits to liabilities/equity/income reduce them - valid but uncommon
      end
    end
  end
end
```

### 4. Update Query Methods

**Refactor Transaction model class methods:**

Current (SQL gymnastics):
```ruby
def self.expenses_by_category(user, year=nil, month=nil)
  sJoinsExpenseA = "LEFT JOIN accounts as accts_cr ON accts_cr.id = transactions.acct_id_cr"
  sJoinsExpenseB = "LEFT JOIN accounts as accts_dr ON accts_dr.id = transactions.acct_id_dr"

  # ... 30 lines of SQL string building ...

  user.transactions
    .joins(sJoinsExpenseA)
    .joins(sJoinsExpenseB)
    .where("(acct_id_dr in (select id from accounts where account_type = 'Asset' or account_type = 'Liability') "\
      "AND acct_id_cr in (select id from accounts where account_type = 'Expense')) "\
        "OR "\
      "(acct_id_cr in (select id from accounts where account_type = 'Asset' or account_type = 'Liability') "\
      "AND acct_id_dr in (select id from accounts where account_type = 'Expense'))")
    # ... more complexity
end
```

New (clean ActiveRecord):
```ruby
def self.expenses_by_category(user, year=nil, month=nil)
  user.transactions
    .joins(entries: :account)
    .where(transaction_entries: { debit_amount: 1.. }) # has a debit
    .where(accounts: { account_type: 'Expense' })
    .in_month_year(month, year)
    .group('accounts.id', 'accounts.name')
    .select(
      'accounts.id as account_id',
      'accounts.name as account_name',
      'SUM(transaction_entries.debit_amount) as total_expenses'
    )
end

# Even simpler with proper scopes:
def self.expenses_by_category(user, year=nil, month=nil)
  TransactionEntry
    .joins(:transaction, :account)
    .debits
    .merge(Transaction.for_user(user).in_month_year(month, year))
    .merge(Account.expense)
    .group('accounts.id', 'accounts.name')
    .sum(:debit_amount)
end
```

**Add useful scopes:**
```ruby
class Transaction < ApplicationRecord
  scope :for_user, ->(user) { where(user_id: user.id) }
  scope :in_year, ->(year) { where('YEAR(tx_date) = ?', year) if year }
  scope :in_month_year, ->(month, year) {
    # existing logic, already defined
  }

  # New semantic scopes
  scope :with_expense_entries, -> {
    joins(entries: :account).where(accounts: { account_type: 'Expense' }).distinct
  }

  scope :with_income_entries, -> {
    joins(entries: :account).where(accounts: { account_type: 'Income' }).distinct
  }
end

class TransactionEntry < ApplicationRecord
  scope :for_account, ->(account) { where(account_id: account.id) }
  scope :for_account_type, ->(type) { joins(:account).where(accounts: { account_type: type }) }
  scope :debits, -> { where.not(debit_amount: nil) }
  scope :credits, -> { where.not(credit_amount: nil) }
  scope :in_period, ->(start_date, end_date) {
    joins(:transaction).where(transactions: { tx_date: start_date..end_date })
  }
end
```

### 5. Update Controllers

**Modify transaction creation/update:**

Current controller creates transaction with direct debit/credit:
```ruby
def create
  @transaction = @user.transactions.create(transaction_params)
  # ...
end

def transaction_params
  params.require(:transaction).permit(:credit, :acct_id_dr, :debit, :acct_id_cr, ...)
end
```

New controller creates transaction with nested entries:
```ruby
def create
  @transaction = @user.transactions.new(transaction_params)

  if @transaction.save
    # success
  else
    # show errors (including balance validation)
  end
end

def transaction_params
  params.require(:transaction).permit(
    :tx_date, :posting_date, :description, :notes,
    entries_attributes: [:id, :account_id, :debit_amount, :credit_amount, :memo, :_destroy]
  )
end
```

**Refactor controller queries:**

Replace all direct column access:
- `transactions.debit` → `transaction_entries.debit_amount`
- `transactions.credit` → `transaction_entries.credit_amount`
- `acct_id_dr` → `transaction_entries.account_id WHERE debit_amount IS NOT NULL`
- `acct_id_cr` → `transaction_entries.account_id WHERE credit_amount IS NOT NULL`

**CSV Import Controller Updates:**

```ruby
class TransactionImportsController < ApplicationController
  def import
    csv_file = params[:csv_file]
    bank_account = current_user.accounts.find(params[:bank_account_id])

    # Find or create suspense accounts
    uncategorized_expense = Account.find_by(name: 'Uncategorized Expenses')
    uncategorized_income = Account.find_by(name: 'Uncategorized Income')

    CSV.foreach(csv_file.path, headers: true) do |row|
      amount = row['amount'].to_f.abs
      description = row['description']
      tx_date = Date.parse(row['date'])

      # Determine if this is income or expense based on sign in CSV
      is_expense = row['amount'].to_f < 0

      if is_expense
        # Money leaving bank account (expense)
        current_user.transactions.create!(
          tx_date: tx_date,
          description: description,
          entries_attributes: [
            { account_id: bank_account.id, credit_amount: amount },           # Bank decreases
            { account_id: uncategorized_expense.id, debit_amount: amount }    # Suspense
          ]
        )
      else
        # Money entering bank account (income)
        current_user.transactions.create!(
          tx_date: tx_date,
          description: description,
          entries_attributes: [
            { account_id: bank_account.id, debit_amount: amount },            # Bank increases
            { account_id: uncategorized_income.id, credit_amount: amount }    # Suspense
          ]
        )
      end
    end

    redirect_to uncategorized_transactions_path,
                notice: "Imported #{count} transactions. Please categorize them."
  end
end
```

**Uncategorized Transactions Controller:**

```ruby
class TransactionsController < ApplicationController
  def uncategorized
    @user = current_user
    @year = params[:year]&.to_i || Date.today.year
    @month = params[:month]&.to_i

    # Find all transactions with uncategorized entries
    @pagy, @transactions = pagy(
      @user.transactions
        .uncategorized
        .in_month_year(@month, @year)
        .order(tx_date: :desc)
    )

    respond_to do |format|
      format.html
    end
  end

  def categorize
    @user = current_user
    @transaction = @user.transactions.find(params[:id])

    # Find the uncategorized entry
    uncategorized_entry = @transaction.uncategorized_entries.first

    # Update to proper account
    new_account = @user.accounts.find(params[:account_id])

    if uncategorized_entry.update(account_id: new_account.id)
      redirect_to uncategorized_transactions_path,
                  notice: 'Transaction categorized successfully'
    else
      redirect_to uncategorized_transactions_path,
                  alert: 'Failed to categorize transaction'
    end
  end
end
```

### 6. Update Views/Forms

**Transaction form (new/edit):**
```erb
<%= form_with model: @transaction do |f| %>
  <%= f.label :tx_date %>
  <%= f.date_field :tx_date %>

  <%= f.label :description %>
  <%= f.text_field :description %>

  <h3>Entries</h3>
  <div id="entries">
    <%= f.fields_for :entries do |entry_form| %>
      <%= render 'entry_fields', f: entry_form %>
    <% end %>
  </div>

  <%= link_to_add_association 'Add Entry', f, :entries %>

  <div class="balance-display">
    Debits: <span id="total-debits">0.00</span>
    Credits: <span id="total-credits">0.00</span>
    <span id="balance-indicator"></span>
  </div>

  <%= f.submit %>
<% end %>
```

**Entry fields partial:**
```erb
<div class="entry-fields">
  <%= f.select :account_id,
      options_for_select(@accounts.map { |a| [a.name, a.id] }),
      { prompt: 'Select Account' } %>

  <%= f.number_field :debit_amount, placeholder: 'Debit', step: 0.01 %>
  <%= f.number_field :credit_amount, placeholder: 'Credit', step: 0.01 %>

  <%= f.text_field :memo, placeholder: 'Memo (optional)' %>

  <%= link_to_remove_association 'Remove', f %>
</div>
```

**JavaScript for balance validation:**
```javascript
// Real-time balance calculation
document.addEventListener('turbo:load', () => {
  const form = document.querySelector('#transaction-form');
  if (!form) return;

  form.addEventListener('input', (e) => {
    if (e.target.matches('[name*="debit_amount"], [name*="credit_amount"]')) {
      updateBalance();
    }
  });

  function updateBalance() {
    let totalDebits = 0;
    let totalCredits = 0;

    document.querySelectorAll('[name*="debit_amount"]').forEach(input => {
      totalDebits += parseFloat(input.value) || 0;
    });

    document.querySelectorAll('[name*="credit_amount"]').forEach(input => {
      totalCredits += parseFloat(input.value) || 0;
    });

    document.getElementById('total-debits').textContent = totalDebits.toFixed(2);
    document.getElementById('total-credits').textContent = totalCredits.toFixed(2);

    const indicator = document.getElementById('balance-indicator');
    if (totalDebits === totalCredits && totalDebits > 0) {
      indicator.textContent = '✓ Balanced';
      indicator.className = 'balanced';
    } else {
      indicator.textContent = '✗ Unbalanced';
      indicator.className = 'unbalanced';
    }
  }

  updateBalance();
});
```

**Transaction display:**
```erb
<h2>Transaction #<%= @transaction.id %></h2>
<p>Date: <%= @transaction.tx_date %></p>
<p>Description: <%= @transaction.description %></p>

<table>
  <thead>
    <tr>
      <th>Account</th>
      <th>Debit</th>
      <th>Credit</th>
      <th>Memo</th>
    </tr>
  </thead>
  <tbody>
    <% @transaction.entries.each do |entry| %>
      <tr>
        <td><%= entry.account.name %></td>
        <td><%= number_to_currency(entry.debit_amount) if entry.debit_amount %></td>
        <td><%= number_to_currency(entry.credit_amount) if entry.credit_amount %></td>
        <td><%= entry.memo %></td>
      </tr>
    <% end %>
  </tbody>
  <tfoot>
    <tr>
      <td><strong>Total</strong></td>
      <td><strong><%= number_to_currency(@transaction.total_debits) %></strong></td>
      <td><strong><%= number_to_currency(@transaction.total_credits) %></strong></td>
      <td></td>
    </tr>
  </tfoot>
</table>
```

**Uncategorized transactions view:**
```erb
<h2>Uncategorized Transactions</h2>
<p class="alert alert-info">
  These transactions were imported but haven't been categorized yet.
  Select the appropriate account for each transaction:
  <strong>Expenses/Income</strong> for true expenses/income,
  <strong>Assets</strong> for transfers between accounts,
  <strong>Liabilities</strong> for debt payments.
</p>

<table>
  <thead>
    <tr>
      <th>Date</th>
      <th>Description</th>
      <th>Amount</th>
      <th>Current Status</th>
      <th>Categorize As</th>
      <th>Actions</th>
    </tr>
  </thead>
  <tbody>
    <% @transactions.each do |txn| %>
      <% uncategorized_entry = txn.uncategorized_entries.first %>
      <tr>
        <td><%= txn.tx_date.strftime('%Y-%m-%d') %></td>
        <td><%= txn.description %></td>
        <td><%= number_to_currency(uncategorized_entry.amount) %></td>
        <td>
          <span class="badge badge-warning">
            <%= uncategorized_entry.account.name %>
          </span>
        </td>
        <td>
          <%= form_with url: categorize_transaction_path(txn), method: :patch do |f| %>
            <%= f.select :account_id,
                grouped_options_for_select(
                  {
                    'Expenses' => @user.accounts.expense.order(:name).map { |a| [a.name, a.id] },
                    'Income' => @user.accounts.income.order(:name).map { |a| [a.name, a.id] },
                    'Assets (Transfers)' => @user.accounts.asset.order(:name).map { |a| [a.name, a.id] },
                    'Liabilities (Debt Payments)' => @user.accounts.liability.order(:name).map { |a| [a.name, a.id] }
                  }
                ),
                { prompt: 'Select category...' },
                { class: 'form-control' } %>
        </td>
        <td>
            <%= f.submit 'Categorize', class: 'btn btn-primary btn-sm' %>
          <% end %>
        </td>
      </tr>
    <% end %>
  </tbody>
</table>

<div class="summary">
  <p><strong>Total uncategorized:</strong> <%= @pagy.count %> transactions</p>
</div>

<%= pagy_nav(@pagy) if @pagy.pages > 1 %>
```

### 7. Testing & Validation

**Model tests:**
```ruby
describe Transaction do
  describe 'validations' do
    it 'requires debits to equal credits' do
      transaction = Transaction.new(tx_date: Date.today)
      transaction.entries.build(account: asset_account, debit_amount: 100)
      transaction.entries.build(account: expense_account, credit_amount: 90)

      expect(transaction).not_to be_valid
      expect(transaction.errors[:base]).to include(/Debits.*must equal credits/)
    end

    it 'requires at least 2 entries' do
      transaction = Transaction.new(tx_date: Date.today)
      transaction.entries.build(account: asset_account, debit_amount: 100)

      expect(transaction).not_to be_valid
    end

    it 'accepts balanced multi-leg transactions' do
      transaction = Transaction.new(tx_date: Date.today)
      transaction.entries.build(account: cash_account, credit_amount: 100)
      transaction.entries.build(account: meals_expense, debit_amount: 60)
      transaction.entries.build(account: entertainment_expense, debit_amount: 40)

      expect(transaction).to be_valid
    end
  end

  describe '#balanced?' do
    it 'returns true when debits equal credits' do
      # ...
    end
  end
end

describe TransactionEntry do
  it 'requires exactly one of debit or credit' do
    entry = TransactionEntry.new(account: asset_account, debit_amount: 100, credit_amount: 100)
    expect(entry).not_to be_valid

    entry = TransactionEntry.new(account: asset_account)
    expect(entry).not_to be_valid
  end

  it 'requires positive amounts' do
    entry = TransactionEntry.new(account: asset_account, debit_amount: -50)
    expect(entry).not_to be_valid
  end
end
```

**Integration tests:**
```ruby
describe 'Transaction creation' do
  it 'creates a simple expense transaction' do
    visit new_transaction_path

    fill_in 'Date', with: Date.today
    fill_in 'Description', with: 'Coffee shop'

    # First entry: Credit Cash
    within('.entry-fields:nth-child(1)') do
      select 'Cash', from: 'Account'
      fill_in 'Credit', with: '5.00'
    end

    # Second entry: Debit Meals Expense
    click_link 'Add Entry'
    within('.entry-fields:nth-child(2)') do
      select 'Meals Expense', from: 'Account'
      fill_in 'Debit', with: '5.00'
    end

    # Should show balanced
    expect(page).to have_content('✓ Balanced')

    click_button 'Create Transaction'

    expect(page).to have_content('Transaction was successfully created')
    expect(Transaction.last.entries.count).to eq(2)
  end

  it 'prevents creating unbalanced transaction' do
    # ... test validation
  end
end

describe 'CSV Import and Categorization' do
  let(:bank_account) { Account.create!(name: 'Checking Account', account_type: 'Asset', user: user) }
  let(:groceries_account) { Account.create!(name: 'Groceries', account_type: 'Expense', user: user) }
  let(:credit_card_account) { Account.create!(name: 'Visa', account_type: 'Liability', user: user) }
  let(:uncategorized_expense) { Account.create!(name: 'Uncategorized Expenses', account_type: 'Expense') }

  it 'imports CSV with suspense accounts' do
    csv_content = <<~CSV
      date,description,amount
      2025-10-17,Store Purchase,-30.00
      2025-10-17,Paycheck,2000.00
    CSV

    visit import_transactions_path
    attach_file 'CSV File', csv_file
    select 'Checking Account', from: 'Bank Account'
    click_button 'Import'

    expect(Transaction.count).to eq(2)

    # Expense transaction uses suspense account
    expense_txn = Transaction.find_by(description: 'Store Purchase')
    expect(expense_txn.entries.count).to eq(2)
    expect(expense_txn.entries.find_by(debit_amount: 30.00).account).to eq(uncategorized_expense)
    expect(expense_txn.entries.find_by(credit_amount: 30.00).account).to eq(bank_account)
    expect(expense_txn.balanced?).to be true
  end

  it 'categorizes imported transaction as expense' do
    # Create imported transaction with suspense account
    txn = Transaction.create!(
      user: user,
      tx_date: Date.today,
      description: 'Store Purchase',
      entries_attributes: [
        { account_id: bank_account.id, credit_amount: 30.00 },
        { account_id: uncategorized_expense.id, debit_amount: 30.00 }
      ]
    )

    visit uncategorized_transactions_path
    within("tr[data-transaction-id='#{txn.id}']") do
      select 'Groceries', from: 'account_id'
      click_button 'Categorize'
    end

    txn.reload
    expect(txn.uncategorized?).to be false
    expect(txn.entries.find_by(debit_amount: 30.00).account).to eq(groceries_account)

    # Verify impact: Should appear as expense on income statement
    expense_entries = TransactionEntry.joins(:account)
      .where(accounts: { account_type: 'Expense' })
    expect(expense_entries.sum(:debit_amount)).to eq(30.00)
  end

  it 'categorizes imported transaction as transfer (credit card payment)' do
    # Create imported transaction that looks like expense but is actually transfer
    txn = Transaction.create!(
      user: user,
      tx_date: Date.today,
      description: 'Payment to Credit Card',
      entries_attributes: [
        { account_id: bank_account.id, credit_amount: 500.00 },
        { account_id: uncategorized_expense.id, debit_amount: 500.00 }
      ]
    )

    visit uncategorized_transactions_path
    within("tr[data-transaction-id='#{txn.id}']") do
      select 'Visa', from: 'account_id'
      click_button 'Categorize'
    end

    txn.reload
    expect(txn.uncategorized?).to be false

    # Verify entries are now: Debit Liability (Visa), Credit Asset (Bank)
    debit_entry = txn.entries.find_by(debit_amount: 500.00)
    credit_entry = txn.entries.find_by(credit_amount: 500.00)

    expect(debit_entry.account).to eq(credit_card_account)
    expect(debit_entry.account.account_type).to eq('Liability')
    expect(credit_entry.account).to eq(bank_account)
    expect(credit_entry.account.account_type).to eq('Asset')

    # Verify NO impact on income statement (Balance Sheet to Balance Sheet)
    expense_entries = TransactionEntry.joins(:account)
      .where(accounts: { account_type: 'Expense' })
      .where(transaction_id: txn.id)
    expect(expense_entries.count).to eq(0)
  end
end
```

**Data migration tests:**
```ruby
describe 'Data migration' do
  before do
    # Create old-style transactions
    @old_transaction = Transaction.create!(
      user: user,
      tx_date: Date.today,
      details: 'Test transaction',
      acct_id_dr: expense_account.id,
      debit: 50.00,
      acct_id_cr: cash_account.id,
      credit: 50.00
    )
  end

  it 'converts old transactions to new format' do
    run_migration

    @old_transaction.reload
    expect(@old_transaction.entries.count).to eq(2)
    expect(@old_transaction.total_debits).to eq(50.00)
    expect(@old_transaction.total_credits).to eq(50.00)
    expect(@old_transaction.balanced?).to be true
  end

  it 'preserves account balances after migration' do
    balances_before = Account.all.map { |a| [a.id, a.balance] }.to_h

    run_migration

    balances_after = Account.all.map { |a| [a.id, a.balance] }.to_h
    expect(balances_after).to eq(balances_before)
  end
end
```

**Performance tests:**
```ruby
describe 'Query performance' do
  before do
    # Create 10,000 transactions with entries
    10_000.times do
      transaction = Transaction.create!(user: user, tx_date: Date.today)
      transaction.entries.create!(account: cash_account, credit_amount: 100)
      transaction.entries.create!(account: income_account, debit_amount: 100)
    end
  end

  it 'queries expenses efficiently' do
    expect {
      Transaction.expenses_by_category(user, 2025, 10)
    }.to perform_under(100).ms
  end
end
```

### 8. Deprecation & Cleanup

**Phase 1: Deprecation (after validation)**
- Mark old columns as deprecated in schema comments
- Add deprecation warnings to any code still using old columns
- Run app in production with both old and new columns for monitoring period

**Phase 2: Final cleanup migration**
```ruby
class RemoveOldTransactionColumns < ActiveRecord::Migration[7.2]
  def up
    # Verify no code is using old columns
    if Transaction.where.not(acct_id_dr: nil).where(
      'NOT EXISTS (SELECT 1 FROM transaction_entries WHERE transaction_id = transactions.id)'
    ).exists?
      raise "Found transactions with old data but no entries - migration not complete"
    end

    remove_column :transactions, :debit
    remove_column :transactions, :credit
    remove_column :transactions, :acct_id_dr
    remove_column :transactions, :acct_id_cr
    remove_column :transactions, :tx_type
    remove_column :transactions, :acct_id_dr_proposed
    remove_column :transactions, :acct_id_cr_proposed
    remove_column :transactions, :acct_id_dr_proposed_source
    remove_column :transactions, :acct_id_cr_proposed_source

    # Rename details to description for clarity
    rename_column :transactions, :details, :description
  end

  def down
    # Restore old columns if needed
    add_column :transactions, :debit, :decimal, precision: 12, scale: 2
    add_column :transactions, :credit, :decimal, precision: 12, scale: 2
    # ... restore other columns

    rename_column :transactions, :description, :details

    # Populate old columns from entries
    Transaction.find_each do |txn|
      debit_entry = txn.entries.find_by('debit_amount IS NOT NULL')
      credit_entry = txn.entries.find_by('credit_amount IS NOT NULL')

      txn.update_columns(
        debit: debit_entry&.debit_amount,
        acct_id_dr: debit_entry&.account_id,
        credit: credit_entry&.credit_amount,
        acct_id_cr: credit_entry&.account_id
      )
    end
  end
end
```

## Migration Risks & Mitigations

### Risk: Data loss during migration
**Mitigation**:
- Full database backup before migration
- Keep old columns until fully validated (weeks/months)
- Write reversible migration with rollback capability
- Dry-run on production database copy
- Incremental rollout with feature flags

### Risk: Breaking existing functionality
**Mitigation**:
- Comprehensive test coverage before switching
- Phase implementation (add new, keep old, migrate gradually)
- Feature flag to toggle between old/new models during transition
- Run both systems in parallel during validation period
- Monitor error rates and rollback if issues detected

### Risk: Performance degradation
**Mitigation**:
- Proper indexes on transaction_entries (transaction_id, account_id)
- Benchmark queries before/after migration
- Optimize with includes/joins to avoid N+1 queries
- Consider database-level materialized views for complex reports
- Load testing with production-size dataset before go-live

### Risk: User confusion with new interface
**Mitigation**:
- Keep UI changes minimal initially (forms still feel similar)
- Add helpful tooltips and balance indicators
- Provide migration guide for power users
- Consider gradual rollout to subset of users first

### Risk: Split transaction feature breaks
**Mitigation**:
- Test split transaction feature extensively
- Split transactions naturally work better with new model (multi-leg support)
- Document new split transaction workflow

## Benefits After Refactoring

1. **Supports complex transactions**: Split expenses across multiple categories naturally
2. **Cleaner queries**: Use ActiveRecord associations instead of SQL strings
3. **Better validation**: Enforce double-entry rules at database and model level
4. **Audit trail**: Each entry explicitly shows which account is affected
5. **Foundation for future features**:
   - Easier to add journals (Cash Receipts, Cash Disbursements, General Journal)
   - Support for adjusting entries and corrections
   - Period-end closing process
   - Trial balance generation
   - Better income statement generation (prerequisite for Opportunity #3)
6. **Maintainability**: Code becomes much more readable and testable
7. **Scalability**: Proper indexing and associations perform better at scale

## Open Questions

1. **Should we rename `transactions` to `journal_entries`?**
   - Pro: More accurate accounting terminology
   - Con: Breaks existing code references, confusing terminology for users
   - **Recommendation**: Keep as `transactions` for user-facing clarity

2. **How to handle the existing `parent_id` for split transactions?**
   - Current model: Split transactions reference parent transaction
   - New model: Split transactions could just be multi-leg transactions with proper categorization
   - **Recommendation**: Keep `parent_id` for backwards compatibility, but make it optional

3. **Should we create different transaction types (CashReceipt, CashDisbursement, GeneralJournal)?**
   - Pro: Matches accounting textbook structure, better audit trail
   - Con: Adds complexity
   - **Recommendation**: Phase 2 feature - add journal_type field to transactions table later

4. **Do we need to preserve `tx_type` or can it be derived from the accounts involved?**
   - Can be derived: Transaction is expense if any entry debits an Expense account
   - **Recommendation**: Remove `tx_type` - derive it dynamically from entries

5. **Should we support batch imports with the new structure?** ✅ RESOLVED
   - Current import process expects simple 2-account transactions
   - **Resolution**: CSV import creates proper 2-entry transactions using Suspense Accounts. When importing, one entry goes to the bank account (known), the other goes to "Uncategorized Expenses" or "Uncategorized Income" (to be categorized later by user). See "CSV Import Controller Updates" in section 5 for implementation details.

6. **How to handle uncategorized transactions (NULL account_id)?** ✅ RESOLVED
   - Current system allows transactions with NULL account_id for imported transactions awaiting categorization
   - New system requires every entry to have an account (proper double-entry)
   - **Resolution**: Use **Suspense Account Pattern** (standard accounting practice). Create "Uncategorized Expenses" and "Uncategorized Income" accounts. During import, transactions are created with one entry to the bank account and another to the appropriate suspense account. User later updates the suspense entry to the correct account. This maintains double-entry integrity at all times while supporting the import-then-categorize workflow. See "Handling Uncategorized Imports" section for full details.

## Timeline Estimate

- **Week 1-2**: Database schema design and migration scripts
- **Week 3**: Data migration testing on copy of production database
- **Week 4-5**: Model updates and comprehensive testing
- **Week 6-7**: Controller refactoring and query optimization
- **Week 8**: View/form updates with real-time balance validation
- **Week 9**: Integration testing and bug fixes
- **Week 10**: Performance testing and optimization
- **Week 11**: Deployment to staging, user acceptance testing
- **Week 12**: Production deployment with monitoring
- **Week 13-16**: Parallel operation period (both systems running)
- **Week 17**: Final cleanup - remove old columns

**Total**: ~4 months for complete, safe migration

## Success Criteria

- [ ] All existing transactions successfully migrated with 100% data integrity
- [ ] Account balances match before and after migration
- [ ] All queries return identical results (or better) compared to old system
- [ ] Query performance maintained or improved
- [ ] Zero data loss
- [ ] Users can create multi-leg transactions
- [ ] All tests passing (unit, integration, system)
- [ ] Documentation updated
- [ ] Old columns removed from schema
- [ ] SQL gymnastics eliminated from codebase
