class LoadData < ActiveRecord::Migration[4.2]
  def change
    Rake::Task['db:data:load'].invoke

    # Move categories into accounts
    Account.connection.execute('INSERT INTO accounts (cat_id, accounts.name, description, account_type)
    select id as cat_id, categories.name, description, cat_type as account_type from categories;')

    # Update transactions in asset accounts
    Transaction.connection.execute('UPDATE transactions SET credit=(@temp:=credit),
    credit = debit, debit = @temp')

    ### SET new debit account IDs from new category ID on joint & Geordie Vancity
    Transaction.connection.execute('UPDATE transactions t
    left join accounts a on a.cat_id = t.category_id
    SET acct_id_dr = a.id, debit = credit
    WHERE
    credit > 0
    AND (debit = 0 or debit IS NULL)
    AND category_id != 27;')

    ### SET new credit account IDs from new category ID on joint & Geordie Vancity
    Transaction.connection.execute('UPDATE transactions t
    left join accounts a on a.cat_id = t.category_id
    SET acct_id_cr = a.id, credit = debit
    WHERE
    debit > 0
    AND (credit = 0 or credit IS NULL)
    AND category_id != 27;')

    ### SET new credit account IDs from old account_id on joint & Geordie Vancity
    Transaction.connection.execute('UPDATE transactions set acct_id_cr = account_id
    WHERE acct_id_cr IS NULL and acct_id_dr IS NOT NULL and category_id != 27
    AND (account_id = 1 or account_id = 21);')

    Transaction.connection.execute('UPDATE transactions set acct_id_dr = account_id
    WHERE acct_id_dr IS NULL and acct_id_cr IS NOT NULL and category_id != 27
    AND (account_id = 1 or account_id = 21);')

    ### SET new credit account IDs from old account_id on VISAs
    Transaction.connection.execute('UPDATE transactions set acct_id_cr = account_id
    WHERE acct_id_cr IS NULL and acct_id_dr IS NOT NULL and category_id != 27
    AND (account_id = 11 or account_id = 31);')

    Transaction.connection.execute('UPDATE transactions set acct_id_dr = account_id
    WHERE acct_id_dr IS NULL and acct_id_cr IS NOT NULL and category_id != 27
    AND (account_id = 11 or account_id = 31);')

    Transaction.connection.execute('UPDATE transactions set acct_id_cr = account_id
    where credit != debit AND debit = 0 AND category_id = 27;')

    Transaction.connection.execute('UPDATE transactions set acct_id_dr = account_id
    where credit != debit AND credit = 0 AND category_id = 27;')

    Account.connection.execute('UPDATE accounts set import_class = TRUE
    WHERE account_type not in ("Expense", "Income", "Asset", "Liability")
    AND account_type IS NOT NULL;')

    Account.connection.execute('UPDATE accounts set account_type = "Asset"
    WHERE id = 1 or id = 21;')

    Account.connection.execute('UPDATE accounts set account_type = "Liability"
    WHERE id = 11 or id = 31;')

    Account.connection.execute('UPDATE accounts set account_type = "Expense"
    WHERE account_type IS NULL;')

  end
end
