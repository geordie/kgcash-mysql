# Plan: Convert User-Account Relationship from Many-to-Many to One-to-Many

**Date**: 2025-10-18
**Status**: In Progress

## Todo List

- [x] Document the plan (THIS FILE)
- [x] Create migration to add user_id to accounts and drop accounts_users table
- [x] Update User model to use has_many :accounts
- [x] Update Account model to use belongs_to :user
- [x] Update user_fabricator.rb to work with new association
- [x] Update all test files using user.accounts << pattern
- [x] Run migration
- [x] Fix account fabricator to automatically create user
- [x] Fix transaction_entry_spec to use shared user
- [ ] Run tests to verify changes (user will do this)

## Additional Changes for Test Suite

### Account Fabricator
Updated `spec/fabricators/account_fabricator.rb` to automatically create a user for each account:
```ruby
Fabricator(:account, :class_name => "Account") do
  user  # Added this line
  name { Faker::Name.first_name }
  account_type { %w(Asset Expense Income Liability).sample }
end
```

This ensures that all fabricated accounts have a valid user association, which is now required by the `belongs_to :user` relationship.

### TransactionEntry Spec
Updated `spec/models/transaction_entry_spec.rb` scopes section to use a shared user for all accounts and transactions to ensure data consistency in tests.

## Note on Documents

The Documents model also uses `has_and_belongs_to_many :users` with a `documents_users` join table. This was left unchanged as it may legitimately support multi-user document sharing. If this also needs to be converted to a one-to-many relationship, follow the same pattern as the accounts conversion.

---

## Overview

Convert the user-account relationship from a many-to-many (has_and_belongs_to_many) to a one-to-many (user has_many accounts, account belongs_to user) relationship. Analysis shows no features depend on multi-user account sharing.

## Current State

### Database Schema
- `accounts_users` join table with `account_id` and `user_id` columns
- Supports many-to-many relationship

### Models
```ruby
# User model (app/models/user.rb:13)
has_and_belongs_to_many :accounts

# Account model (app/models/account.rb:6)
has_and_belongs_to_many :users
```

### Development Database
- Currently empty (0 accounts, 0 users, 0 join table entries)
- No existing production data to migrate

## Analysis Findings

### How the Association is Currently Used

1. **Account Creation**: `user.accounts << account` pattern in user.rb:73,81
2. **Account Access**: All code uses `user.accounts` or `@user.accounts`
   - accounts_controller.rb:9-12,24,58,63,80,248
   - All controller actions scope to current user's accounts
3. **Tests**: 40+ instances in specs use `user.accounts << account`
4. **No Reverse Usage**: **ZERO** code accesses `account.users` or expects multiple users per account

### Conclusion
- No features require or depend on multi-user account sharing
- All authorization already scoped to individual users
- Safe to convert to one-to-many relationship

## Migration Plan

### Step 1: Database Migration

Create migration to:
1. Add `user_id` foreign key column to `accounts` table
2. Migrate existing data from `accounts_users` to `accounts.user_id`
3. Drop `accounts_users` join table

**Migration file**: `db/migrate/YYYYMMDDHHMMSS_convert_accounts_to_belong_to_user.rb`

```ruby
class ConvertAccountsToBelongToUser < ActiveRecord::Migration[7.0]
  def up
    # Add user_id to accounts table
    add_reference :accounts, :user, foreign_key: true, index: true

    # Migrate data from accounts_users to accounts.user_id
    execute <<-SQL
      UPDATE accounts a
      INNER JOIN (
        SELECT account_id, MIN(user_id) as user_id
        FROM accounts_users
        GROUP BY account_id
      ) au ON a.id = au.account_id
      SET a.user_id = au.user_id
    SQL

    # Drop the join table
    drop_table :accounts_users
  end

  def down
    # Recreate the join table
    create_table :accounts_users do |t|
      t.integer :account_id
      t.integer :user_id
    end

    # Migrate data back
    execute <<-SQL
      INSERT INTO accounts_users (account_id, user_id)
      SELECT id, user_id
      FROM accounts
      WHERE user_id IS NOT NULL
    SQL

    # Remove user_id from accounts
    remove_reference :accounts, :user
  end
end
```

### Step 2: Update Models

**User model** (app/models/user.rb:13):
```ruby
# Change from:
has_and_belongs_to_many :accounts

# To:
has_many :accounts, dependent: :destroy
```

**Account model** (app/models/account.rb:6):
```ruby
# Change from:
has_and_belongs_to_many :users

# To:
belongs_to :user
```

### Step 3: Update User Model Methods

**user.rb:66-82** - Update `create_suspense_accounts` method:
```ruby
# Change from:
expense_account = Account.create!(...)
accounts << expense_account

# To:
accounts.create!(
  name: 'Uncategorized Expenses',
  account_type: 'Expense',
  description: '...'
)
```

### Step 4: Update Test Fabricators

**spec/fabricators/user_fabricator.rb:2-16**:
The current fabricator creates accounts and associates them via HABTM. Need to update to create accounts with user association.

### Step 5: Update Test Files (40+ locations)

Replace all instances of:
```ruby
user.accounts << account
```

With:
```ruby
account.user = user
account.save!
# OR
user.accounts << account  # Still works with has_many
```

**Files to update:**
- db/migrate/20251018130000_create_user_suspense_accounts.rb (2 instances)
- spec/models/transaction_queries_spec.rb (8 instances)
- spec/models/account_balance_spec.rb (6 instances)
- spec/models/transaction_regression_spec.rb (12 instances)
- spec/models/transaction_balance_spec.rb (4 instances)
- spec/features/csv_import_spec.rb (2 instances)
- spec/features/categorization_spec.rb (6 instances)
- app/models/user.rb (2 instances)

### Step 6: Consider Documents Association

Note: Documents also use HABTM with users (documents_users table). Determine if this should also be converted or left as-is for multi-user document sharing.

## Testing Strategy

1. Run full test suite after each change
2. Verify account creation works correctly
3. Verify account scoping to users works
4. Verify cascading deletes work (user deletion removes accounts)
5. Test manually in development environment

## Rollback Plan

The migration includes a `down` method to reverse changes if needed:
1. Recreates `accounts_users` join table
2. Migrates data back from `accounts.user_id`
3. Removes `user_id` column from accounts

## Benefits

1. **Simpler mental model**: One user owns their accounts
2. **Better data integrity**: Foreign key constraint enforces user ownership
3. **Clearer authorization**: Explicit user ownership
4. **Performance**: Eliminates join table queries
5. **Cascading deletes**: Can easily clean up accounts when user is deleted

## Risks

1. **Breaking change**: Requires code updates across codebase
2. **Test updates**: 40+ test file locations need updates
3. **Migration complexity**: Need to handle edge cases in data migration

## Implementation Order

1. ✅ Document the plan
2. ⏳ Create database migration
3. ⏳ Update User model
4. ⏳ Update Account model
5. ⏳ Update user fabricator
6. ⏳ Update test files
7. ⏳ Run migration
8. ⏳ Run test suite
9. ⏳ Manual testing
10. ⏳ Commit changes
