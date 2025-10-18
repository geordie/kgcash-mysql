# Split Transaction Migration Strategy: Multi-Leg Entries Approach

**Date**: 2025-10-18
**Status**: Planning
**Related**: [Transaction Migration Plan](2025-10-17-transaction_migration_plan.md)

## Executive Summary

Migrate from parent/child split transaction model to proper double-entry multi-leg entries. This eliminates the `parent_id` hierarchy in favor of single transactions with multiple entries, following standard accounting practices.

## Current Split Transaction System

### How It Works Now

```
User imports: $100 spent at "Store XYZ"
Creates: Transaction #123 (Checking → Uncategorized, $100)

User splits into Groceries ($60) and Entertainment ($40)
Creates:
  - Transaction #123: $100 Checking → Uncategorized (parent_id: NULL)
  - Transaction #124: $60 Checking → Groceries (parent_id: 123)
  - Transaction #125: $40 Checking → Entertainment (parent_id: 123)
```

### Problems with Current Approach

1. **Three separate transaction records** for one real-world event
2. **Accounting ambiguity**: Which transaction is "the real one"?
3. **Reporting complexity**: Must filter out parent OR children to avoid double-counting
4. **Not standard double-entry**: Doesn't match how accountants actually record splits
5. **Query complexity**: Every report needs special logic for `parent_id`

### Current Database Schema

```ruby
transactions:
  - id: 123
  - debit: 100.00
  - credit: 100.00
  - acct_id_dr: (Uncategorized)
  - acct_id_cr: (Checking)
  - parent_id: NULL

  - id: 124
  - debit: 60.00
  - credit: 60.00
  - acct_id_dr: (Groceries)
  - acct_id_cr: (Checking)
  - parent_id: 123  ← Child references parent

  - id: 125
  - debit: 40.00
  - credit: 40.00
  - acct_id_dr: (Entertainment)
  - acct_id_cr: (Checking)
  - parent_id: 123  ← Child references parent
```

## Recommended Approach: Option 1 - Multi-Leg Entries

### Core Concept

A "split transaction" is actually a **multi-leg journal entry** - ONE transaction with 3+ entries. This is standard double-entry bookkeeping.

### New Structure

```
User imports: $100 spent at "Store XYZ"
Creates: Transaction #123 with 2 entries

User splits into Groceries ($60) and Entertainment ($40)
Modifies: Transaction #123 to have 3 entries:
  - Entry 1: Credit Checking $100
  - Entry 2: Debit Groceries $60
  - Entry 3: Debit Entertainment $40
```

### New Database Schema

```ruby
transactions:
  - id: 123
  - tx_date: 2025-10-17
  - description: "Store XYZ"
  - split_at: 2025-10-17 14:30:00  ← Audit timestamp
  - split_source_ids: "[124, 125]"  ← Original child IDs for reference

transaction_entries:
  - id: 1
  - transaction_id: 123
  - account_id: (Checking)
  - credit_amount: 100.00
  - debit_amount: NULL

  - id: 2
  - transaction_id: 123
  - account_id: (Groceries)
  - credit_amount: NULL
  - debit_amount: 60.00

  - id: 3
  - transaction_id: 123
  - account_id: (Entertainment)
  - credit_amount: NULL
  - debit_amount: 40.00
```

## Benefits of Multi-Leg Approach

### 1. Accounting Correctness
- ✅ Matches how paper accounting ledgers work
- ✅ One transaction = one real-world event
- ✅ Standard double-entry bookkeeping practice
- ✅ Foundation for proper accounting features (trial balance, general ledger, etc.)

### 2. Reconciliation
- ✅ Bank shows one $100 transaction → system shows one transaction
- ✅ Transaction count matches bank statement
- ✅ No confusion about which record to reconcile against

### 3. Reporting Simplicity
- ✅ No risk of double-counting
- ✅ No special `parent_id` logic in queries
- ✅ Sum all entries = correct totals
- ✅ Easier to understand code

### 4. Data Model Simplicity
- ✅ Eliminates `parent_id` column and logic
- ✅ No need to decide "include parent or children?"
- ✅ Fewer transaction records in database
- ✅ More intuitive for developers

### 5. Flexibility
- ✅ Natural support for unlimited splits (not just 2-way)
- ✅ Can add/remove entries to "re-split" anytime
- ✅ Supports complex multi-category transactions
- ✅ No artificial limit on split depth/complexity

## Migration Strategy

### Phase 1: Create Schema

**Migration file**: `20251018120000_create_transaction_entries.rb`

```ruby
create_table :transaction_entries do |t|
  t.references :transaction, null: false, foreign_key: true
  t.references :account, null: false, foreign_key: true
  t.decimal :debit_amount, precision: 12, scale: 2
  t.decimal :credit_amount, precision: 12, scale: 2
  t.text :memo
  t.timestamps

  # Constraints: exactly one amount, must be positive
  t.check_constraint "(debit_amount IS NOT NULL AND credit_amount IS NULL) OR
                      (debit_amount IS NULL AND credit_amount IS NOT NULL)"
  t.check_constraint "debit_amount IS NULL OR debit_amount >= 0"
  t.check_constraint "credit_amount IS NULL OR credit_amount >= 0"
end

# Add audit columns to transactions
add_column :transactions, :split_at, :datetime
add_column :transactions, :split_source_ids, :text
```

### Phase 2: Migrate Data

**Migration file**: `20251018120100_migrate_split_transactions_to_entries.rb`

#### Step 1: Migrate Simple Transactions (No Splits)

```ruby
# For each transaction WITHOUT children (parent_id IS NULL and no children)
Transaction.where(parent_id: nil).find_each do |txn|
  next if Transaction.exists?(parent_id: txn.id) # Skip if has children

  # Create debit entry
  if txn.acct_id_dr.present? && txn.debit.present? && txn.debit > 0
    TransactionEntry.create!(
      transaction_id: txn.id,
      account_id: txn.acct_id_dr,
      debit_amount: txn.debit,
      memo: nil
    )
  end

  # Create credit entry
  if txn.acct_id_cr.present? && txn.credit.present? && txn.credit > 0
    TransactionEntry.create!(
      transaction_id: txn.id,
      account_id: txn.acct_id_cr,
      credit_amount: txn.credit,
      memo: nil
    )
  end
end
```

#### Step 2: Migrate Split Transactions (Parent + Children)

```ruby
# Find all parent transactions (those that have children)
parent_ids = Transaction.where.not(parent_id: nil).distinct.pluck(:parent_id)

Transaction.where(id: parent_ids).find_each do |parent_txn|
  child_txns = Transaction.where(parent_id: parent_txn.id).order(:id)

  # Get all the child transaction IDs for audit trail
  child_ids = child_txns.pluck(:id)

  # Strategy: Use children only, discard parent
  # Rationale: Children have the correct categorization, parent is usually "Uncategorized"

  # Find the credit account (bank account) from first child
  credit_account_id = child_txns.first.acct_id_cr
  total_amount = child_txns.sum(:credit)

  # Create one credit entry for the bank account
  TransactionEntry.create!(
    transaction_id: parent_txn.id,
    account_id: credit_account_id,
    credit_amount: total_amount,
    memo: nil
  )

  # Create debit entries for each child's category
  child_txns.each do |child|
    TransactionEntry.create!(
      transaction_id: parent_txn.id,
      account_id: child.acct_id_dr,
      debit_amount: child.debit,
      memo: child.notes # Preserve child's notes in entry memo
    )
  end

  # Mark parent as split and preserve child IDs
  parent_txn.update_columns(
    split_at: child_txns.maximum(:created_at), # Use latest child creation time
    split_source_ids: child_ids.to_json
  )

  # Delete child transactions (data now merged into parent)
  child_txns.destroy_all
end
```

#### Step 3: Handle Edge Cases

```ruby
# Find orphaned children (parent_id references non-existent transaction)
orphaned = Transaction.where.not(parent_id: nil)
  .where.not(parent_id: Transaction.select(:id))

orphaned.each do |orphan|
  # Convert orphan to standalone transaction with entries
  # (same logic as simple transaction migration)

  orphan.update_column(:parent_id, nil) # Remove invalid reference

  # Create entries...
end

# Find NULL account situations
null_accounts = Transaction.where("acct_id_dr IS NULL OR acct_id_cr IS NULL")
# Handle with suspense accounts (per main migration plan)
```

### Phase 3: Validation

```ruby
# Validate all transactions are balanced
unbalanced = Transaction.includes(:entries).select do |txn|
  total_debits = txn.entries.sum(:debit_amount).to_f
  total_credits = txn.entries.sum(:credit_amount).to_f
  (total_debits - total_credits).abs > 0.01 # Allow for rounding
end

if unbalanced.any?
  raise "Found #{unbalanced.count} unbalanced transactions: #{unbalanced.map(&:id)}"
end

# Validate all transactions have at least 2 entries
insufficient_entries = Transaction.includes(:entries).select do |txn|
  txn.entries.count < 2
end

if insufficient_entries.any?
  raise "Found #{insufficient_entries.count} transactions with < 2 entries"
end

# Compare account balances before/after
# (Run before migration, save results, run after, compare)
```

### Phase 4: Deprecate Old Columns

After validation period (e.g., 1-2 weeks in production):

```ruby
# Migration: 20251018120200_remove_old_transaction_columns.rb
remove_column :transactions, :debit
remove_column :transactions, :credit
remove_column :transactions, :acct_id_dr
remove_column :transactions, :acct_id_cr
remove_column :transactions, :parent_id
```

## Code Changes Required

### 1. Models

#### Transaction Model

```ruby
class Transaction < ApplicationRecord
  has_many :entries, class_name: 'TransactionEntry', dependent: :destroy
  has_many :accounts, through: :entries

  accepts_nested_attributes_for :entries, allow_destroy: true

  validates_presence_of :tx_date
  validate :debits_equal_credits
  validate :minimum_two_entries

  # Scopes
  scope :split, -> { where.not(split_at: nil) }
  scope :not_split, -> { where(split_at: nil) }

  # Helper methods
  def total_debits
    entries.sum(:debit_amount)
  end

  def total_credits
    entries.sum(:credit_amount)
  end

  def balanced?
    total_debits == total_credits
  end

  def split?
    split_at.present?
  end

  def multi_category?
    # More than 2 entries (complex split)
    entries.count > 2
  end

  def debit_entries
    entries.where.not(debit_amount: nil)
  end

  def credit_entries
    entries.where.not(credit_amount: nil)
  end

  private

  def debits_equal_credits
    unless balanced?
      errors.add(:base, "Debits (#{total_debits}) must equal credits (#{total_credits})")
    end
  end

  def minimum_two_entries
    if entries.size < 2
      errors.add(:base, "Transaction must have at least 2 entries")
    end
  end
end
```

#### TransactionEntry Model

```ruby
class TransactionEntry < ApplicationRecord
  belongs_to :transaction
  belongs_to :account

  validates_presence_of :transaction, :account
  validate :exactly_one_amount
  validate :amount_positive

  scope :debits, -> { where.not(debit_amount: nil) }
  scope :credits, -> { where.not(credit_amount: nil) }
  scope :for_account, ->(account) { where(account_id: account.id) }
  scope :for_account_type, ->(type) {
    joins(:account).where(accounts: { account_type: type })
  }

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
end
```

### 2. Controller Changes

#### ExpensesController - Split Method (NEW)

```ruby
# GET /expenses/:id/split
def split
  @user = current_user
  @transaction = @user.transactions.find(params[:id])
  @accounts = @user.account_selector

  # Check if already split
  if @transaction.split?
    flash[:notice] = "This transaction is already split into multiple categories"
  end

  respond_to do |format|
    format.html
  end
end

# POST /expenses/split_commit
def split_commit
  @user = current_user
  @transaction = @user.transactions.find(params[:tx_id])

  # Get the submitted entries
  entries_params = params[:entries]

  # Start transaction to ensure atomicity
  ActiveRecord::Base.transaction do
    # Remove existing debit entries (keep credit entry to bank account)
    @transaction.entries.debits.destroy_all

    # Create new debit entries for each split category
    entries_params.each do |entry_data|
      account_id = entry_data[:account_id]
      amount = entry_data[:amount].to_f
      notes = entry_data[:notes]

      next if amount <= 0 || account_id.blank?

      @transaction.entries.create!(
        account_id: account_id,
        debit_amount: amount,
        memo: notes
      )
    end

    # Mark as split
    @transaction.update!(split_at: Time.current) unless @transaction.split?

    # Validation will ensure debits = credits
    unless @transaction.balanced?
      raise ActiveRecord::Rollback
    end
  end

  respond_to do |format|
    if @transaction.balanced?
      format.html { redirect_to transaction_path(@transaction), notice: 'Transaction split successfully' }
    else
      format.html { redirect_to split_expense_path(@transaction), alert: 'Split amounts must equal transaction total' }
    end
  end
end
```

### 3. View Changes

#### Split Transaction View

```erb
<%# app/views/expenses/split.html.erb %>

<h3>Split Transaction</h3>

<div class="transaction-summary">
  <p><strong>Date:</strong> <%= @transaction.tx_date.strftime('%Y-%m-%d') %></p>
  <p><strong>Description:</strong> <%= @transaction.description %></p>
  <p><strong>Total Amount:</strong> <%= number_to_currency(@transaction.total_credits) %></p>
</div>

<%= form_with url: split_commit_expenses_path, method: :post do |f| %>
  <%= f.hidden_field :tx_id, value: @transaction.id %>

  <table class="table table-striped">
    <thead>
      <tr>
        <th>Category</th>
        <th>Amount</th>
        <th>Notes</th>
        <th></th>
      </tr>
    </thead>
    <tbody id="split-entries">
      <%= render partial: "split_entry_row",
                 collection: @transaction.debit_entries.presence || [TransactionEntry.new],
                 as: :entry,
                 locals: { f: f, accounts: @accounts } %>
    </tbody>
    <tfoot>
      <tr>
        <td><strong>Total:</strong></td>
        <td><strong><span id="total-split-amount">0.00</span></strong></td>
        <td colspan="2">
          <span id="balance-indicator" class="badge"></span>
        </td>
      </tr>
    </tfoot>
  </table>

  <div class="actions">
    <%= link_to_add_association 'Add Category', f, :entries,
        class: 'btn btn-secondary',
        data: { association_insertion_node: '#split-entries',
                association_insertion_method: 'append' } %>
    <%= f.submit 'Save Split', class: 'btn btn-primary' %>
  </div>
<% end %>

<script>
  // Real-time balance calculation
  document.addEventListener('DOMContentLoaded', function() {
    const transactionTotal = <%= @transaction.total_credits %>;

    function updateBalance() {
      let total = 0;
      document.querySelectorAll('.split-amount').forEach(input => {
        const value = parseFloat(input.value) || 0;
        total += value;
      });

      document.getElementById('total-split-amount').textContent = total.toFixed(2);

      const indicator = document.getElementById('balance-indicator');
      const diff = Math.abs(total - transactionTotal);

      if (diff < 0.01) {
        indicator.textContent = '✓ Balanced';
        indicator.className = 'badge bg-success';
      } else {
        indicator.textContent = `✗ Off by $${diff.toFixed(2)}`;
        indicator.className = 'badge bg-danger';
      }
    }

    document.addEventListener('input', function(e) {
      if (e.target.classList.contains('split-amount')) {
        updateBalance();
      }
    });

    updateBalance();
  });
</script>
```

#### Split Entry Row Partial

```erb
<%# app/views/expenses/_split_entry_row.html.erb %>

<tr class="split-entry-row">
  <td>
    <%= select_tag "entries[][account_id]",
        options_for_select(accounts.map { |a| [a.name, a.id] }, entry.account_id),
        { prompt: 'Select Category', class: 'form-control' } %>
  </td>
  <td>
    <%= number_field_tag "entries[][amount]",
        entry.debit_amount,
        step: 0.01,
        min: 0,
        class: 'form-control split-amount',
        placeholder: '0.00' %>
  </td>
  <td>
    <%= text_field_tag "entries[][notes]",
        entry.memo,
        class: 'form-control',
        placeholder: 'Optional note' %>
  </td>
  <td>
    <button type="button" class="btn btn-sm btn-danger remove-entry">Remove</button>
  </td>
</tr>
```

## User Experience Changes

### Old Workflow
1. View transaction (shows parent)
2. Click "Split"
3. Enter amounts for 2+ child transactions
4. Save → creates separate child transaction records
5. View shows parent + children in list

### New Workflow
1. View transaction (shows single transaction)
2. Click "Split"
3. Enter amounts for multiple categories
4. Save → updates same transaction with multiple entries
5. View shows single transaction with expandable entry details

### UI Indicators

**Transaction List View**:
```
Oct 17  Store XYZ             $100.00  [Split: 2 categories]
                              ↓ Groceries: $60.00
                              ↓ Entertainment: $40.00
```

**Transaction Detail View**:
```
Transaction #123
Date: Oct 17, 2025
Description: Store XYZ

Entries:
┌─────────────────────┬──────────┬──────────┐
│ Account             │ Debit    │ Credit   │
├─────────────────────┼──────────┼──────────┤
│ Checking Account    │          │ $100.00  │
│ Groceries           │  $60.00  │          │
│ Entertainment       │  $40.00  │          │
├─────────────────────┼──────────┼──────────┤
│ Total               │ $100.00  │ $100.00  │ ✓ Balanced
└─────────────────────┴──────────┴──────────┘

[Edit Split] [Delete Transaction]
```

## Testing Strategy

### Unit Tests

```ruby
describe Transaction do
  describe '#split?' do
    it 'returns true for transactions with split_at timestamp' do
      txn = create(:transaction, split_at: Time.current)
      expect(txn.split?).to be true
    end
  end

  describe '#balanced?' do
    it 'returns true when debits equal credits' do
      txn = create(:transaction)
      txn.entries.create!(account: asset_account, credit_amount: 100)
      txn.entries.create!(account: expense_account, debit_amount: 60)
      txn.entries.create!(account: expense_account_2, debit_amount: 40)

      expect(txn.balanced?).to be true
    end
  end
end

describe TransactionEntry do
  it 'requires exactly one of debit or credit' do
    entry = TransactionEntry.new(
      transaction: txn,
      account: account,
      debit_amount: 100,
      credit_amount: 100
    )
    expect(entry).not_to be_valid
  end
end
```

### Integration Tests

```ruby
describe 'Split Transaction Workflow' do
  it 'allows splitting a transaction into multiple categories' do
    txn = create(:transaction)
    create(:transaction_entry, transaction: txn, account: bank_account, credit_amount: 100)
    create(:transaction_entry, transaction: txn, account: uncategorized, debit_amount: 100)

    visit split_expense_path(txn)

    # Remove uncategorized entry, add two specific categories
    within '.split-entry-row:first' do
      select 'Groceries', from: 'entries[][account_id]'
      fill_in 'entries[][amount]', with: '60.00'
    end

    click_link 'Add Category'

    within '.split-entry-row:last' do
      select 'Entertainment', from: 'entries[][account_id]'
      fill_in 'entries[][amount]', with: '40.00'
    end

    expect(page).to have_content('✓ Balanced')

    click_button 'Save Split'

    expect(page).to have_content('Transaction split successfully')

    txn.reload
    expect(txn.entries.debits.count).to eq(2)
    expect(txn.split?).to be true
  end
end
```

### Migration Tests

```ruby
describe 'Split Transaction Migration' do
  it 'merges parent and children into single transaction with entries' do
    # Create old-style split
    parent = create(:transaction,
      debit: 100, credit: 100,
      acct_id_dr: uncategorized.id,
      acct_id_cr: bank_account.id,
      parent_id: nil
    )

    child1 = create(:transaction,
      debit: 60, credit: 60,
      acct_id_dr: groceries.id,
      acct_id_cr: bank_account.id,
      parent_id: parent.id
    )

    child2 = create(:transaction,
      debit: 40, credit: 40,
      acct_id_dr: entertainment.id,
      acct_id_cr: bank_account.id,
      parent_id: parent.id
    )

    # Run migration
    MigrateSplitTransactionsToEntries.new.up

    # Verify results
    parent.reload
    expect(parent.entries.count).to eq(3)
    expect(parent.entries.credits.sum(:credit_amount)).to eq(100)
    expect(parent.entries.debits.sum(:debit_amount)).to eq(100)
    expect(parent.split?).to be true
    expect(parent.split_source_ids).to eq([child1.id, child2.id].to_json)

    # Children should be deleted
    expect(Transaction.exists?(child1.id)).to be false
    expect(Transaction.exists?(child2.id)).to be false
  end
end
```

## Rollback Plan

If issues are discovered after migration:

1. **Immediate rollback**: Keep old columns during validation period
2. **Data recovery**: `split_source_ids` contains original child transaction IDs
3. **Reverse migration**: Recreate children from entries if needed

```ruby
# Emergency rollback migration
def down
  Transaction.where.not(split_at: nil).each do |parent|
    child_ids = JSON.parse(parent.split_source_ids || '[]')

    parent.entries.debits.each_with_index do |entry, index|
      # Recreate child transaction
      child_id = child_ids[index]

      Transaction.create!(
        id: child_id,
        user_id: parent.user_id,
        tx_date: parent.tx_date,
        debit: entry.debit_amount,
        credit: entry.debit_amount,
        acct_id_dr: entry.account_id,
        acct_id_cr: parent.entries.credits.first.account_id,
        parent_id: parent.id,
        details: parent.description,
        notes: entry.memo
      )
    end
  end
end
```

## Timeline

- **Week 1**: Create schema migration and models
- **Week 2**: Write and test data migration script
- **Week 3**: Update controllers and views
- **Week 4**: Integration testing and bug fixes
- **Week 5**: Deploy to staging, user acceptance testing
- **Week 6**: Deploy to production, monitor for issues
- **Week 7-8**: Validation period (parallel operation)
- **Week 9**: Remove old columns if validated

**Total**: ~2 months for safe migration

## Success Criteria

- [ ] All parent/child splits merged into single transactions
- [ ] All transactions have balanced entries (debits = credits)
- [ ] Zero transactions lost during migration
- [ ] Account balances unchanged after migration
- [ ] Transaction count reduced (children removed)
- [ ] Split UI works with new entry-based system
- [ ] All tests passing (unit, integration, migration)
- [ ] User feedback positive on new split workflow
- [ ] No double-counting in financial reports
- [ ] Old columns safely removed

## Open Questions

1. **Should we preserve child transaction IDs permanently or just for audit?**
   - Recommendation: Keep `split_source_ids` for 6-12 months, then drop column

2. **How to handle incomplete splits (parent exists but no children)?**
   - Recommendation: Treat as normal transactions, convert to 2-entry transactions

3. **Should we allow "un-splitting" (merging entries back)?**
   - Recommendation: Yes - just delete extra debit entries, leaving 2 entries

4. **How to display split transactions in CSV exports?**
   - Option A: One row per entry (exploded view)
   - Option B: One row with concatenated categories
   - Recommendation: One row per entry for clarity

## References

- [Main Transaction Migration Plan](2025-10-17-transaction_migration_plan.md)
- [Accounting Standard: Compound Journal Entries](https://en.wikipedia.org/wiki/Journal_entry#Compound_journal_entries)
- [Double-Entry Bookkeeping Principles](https://www.accountingtools.com/articles/what-is-double-entry-bookkeeping)
