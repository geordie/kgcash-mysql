RSpec.describe TransactionEntry, type: :model do

  describe "associations" do
    it "belongs to parent_transaction" do
      entry = Fabricate.build(:transaction_entry)
      expect(entry).to respond_to(:parent_transaction)
      expect(entry.parent_transaction).to be_a(Transaction)
    end

    it "belongs to account" do
      entry = Fabricate.build(:transaction_entry)
      expect(entry).to respond_to(:account)
      expect(entry.account).to be_a(Account)
    end
  end

  describe "validations" do
    describe "exactly_one_amount" do
      context "when both debit and credit are present" do
        it "is invalid" do
          entry = Fabricate.build(:transaction_entry, debit_amount: 100, credit_amount: 100)
          expect(entry).not_to be_valid
          expect(entry.errors[:base]).to include("Entry cannot have both debit and credit")
        end
      end

      context "when neither debit nor credit are present" do
        it "is invalid" do
          entry = Fabricate.build(:transaction_entry, debit_amount: nil, credit_amount: nil)
          expect(entry).not_to be_valid
          expect(entry.errors[:base]).to include("Entry must have either debit or credit")
        end
      end

      context "when only debit is present" do
        it "is valid" do
          entry = Fabricate.build(:debit_entry, debit_amount: 100, credit_amount: nil)
          expect(entry).to be_valid
        end
      end

      context "when only credit is present" do
        it "is valid" do
          entry = Fabricate.build(:credit_entry, debit_amount: nil, credit_amount: 100)
          expect(entry).to be_valid
        end
      end
    end

    describe "amount_positive" do
      context "when debit amount is negative" do
        it "is invalid" do
          entry = Fabricate.build(:debit_entry, debit_amount: -50)
          expect(entry).not_to be_valid
          expect(entry.errors[:debit_amount]).to include("must be positive")
        end
      end

      context "when credit amount is negative" do
        it "is invalid" do
          entry = Fabricate.build(:credit_entry, credit_amount: -50)
          expect(entry).not_to be_valid
          expect(entry.errors[:credit_amount]).to include("must be positive")
        end
      end

      context "when amounts are positive" do
        it "is valid" do
          debit_entry = Fabricate.build(:debit_entry, debit_amount: 50)
          credit_entry = Fabricate.build(:credit_entry, credit_amount: 50)

          expect(debit_entry).to be_valid
          expect(credit_entry).to be_valid
        end
      end

      context "when amounts are zero" do
        it "is valid" do
          debit_entry = Fabricate.build(:debit_entry, debit_amount: 0)
          credit_entry = Fabricate.build(:credit_entry, credit_amount: 0)

          expect(debit_entry).to be_valid
          expect(credit_entry).to be_valid
        end
      end
    end
  end

  describe "scopes" do
    let!(:user) { Fabricate(:user) }
    let!(:transaction) { Fabricate(:transaction, user: user) }
    let!(:asset_account) { Fabricate(:asset, user: user) }
    let!(:expense_account) { Fabricate(:expense, user: user) }
    let!(:debit_entry) { Fabricate(:debit_entry, parent_transaction: transaction, account: expense_account, debit_amount: 50) }
    let!(:credit_entry) { Fabricate(:credit_entry, parent_transaction: transaction, account: asset_account, credit_amount: 50) }

    describe ".debits" do
      it "returns only debit entries" do
        expect(TransactionEntry.debits).to include(debit_entry)
        expect(TransactionEntry.debits).not_to include(credit_entry)
      end
    end

    describe ".credits" do
      it "returns only credit entries" do
        expect(TransactionEntry.credits).to include(credit_entry)
        expect(TransactionEntry.credits).not_to include(debit_entry)
      end
    end

    describe ".for_account" do
      it "returns entries for the specified account" do
        expect(TransactionEntry.for_account(expense_account)).to include(debit_entry)
        expect(TransactionEntry.for_account(expense_account)).not_to include(credit_entry)
      end
    end

    describe ".for_account_type" do
      it "returns entries for the specified account type" do
        expense_entries = TransactionEntry.for_account_type('Expense')
        expect(expense_entries).to include(debit_entry)
        expect(expense_entries).not_to include(credit_entry)
      end
    end
  end

  describe "instance methods" do
    describe "#amount" do
      it "returns debit_amount when present" do
        entry = Fabricate.build(:debit_entry, debit_amount: 75)
        expect(entry.amount).to eq(75)
      end

      it "returns credit_amount when present" do
        entry = Fabricate.build(:credit_entry, credit_amount: 125)
        expect(entry.amount).to eq(125)
      end
    end

    describe "#debit?" do
      it "returns true when debit_amount is present" do
        entry = Fabricate.build(:debit_entry, debit_amount: 50)
        expect(entry.debit?).to be true
      end

      it "returns false when debit_amount is nil" do
        entry = Fabricate.build(:credit_entry, credit_amount: 50)
        expect(entry.debit?).to be false
      end
    end

    describe "#credit?" do
      it "returns true when credit_amount is present" do
        entry = Fabricate.build(:credit_entry, credit_amount: 50)
        expect(entry.credit?).to be true
      end

      it "returns false when credit_amount is nil" do
        entry = Fabricate.build(:debit_entry, debit_amount: 50)
        expect(entry.credit?).to be false
      end
    end
  end

  describe "database constraints" do
    context "when both amounts are present" do
      it "raises database constraint error" do
        user = User.create!(
          username: 'testuser',
          email: 'test@example.com',
          password: 'password',
          salt: 'asdasdastr4325234324sdfds',
          crypted_password: Sorcery::CryptoProviders::BCrypt.encrypt("secret", "asdasdastr4325234324sdfds")
        )
        transaction = Transaction.create!(user: user, tx_date: DateTime.now)
        account = Account.create!(user: user, name: 'Test Account', account_type: 'Expense')

        expect {
          # Bypass Rails validation to test DB constraint
          ActiveRecord::Base.connection.execute(
            "INSERT INTO transaction_entries (transaction_id, account_id, debit_amount, credit_amount, created_at, updated_at)
             VALUES (#{transaction.id}, #{account.id}, 100, 100, NOW(), NOW())"
          )
        }.to raise_error(ActiveRecord::StatementInvalid, /one_amount_required/)
      end
    end

    context "when neither amount is present" do
      it "raises database constraint error" do
        user = User.create!(
          username: 'testuser2',
          email: 'test2@example.com',
          password: 'password',
          salt: 'asdasdastr4325234324sdfds',
          crypted_password: Sorcery::CryptoProviders::BCrypt.encrypt("secret", "asdasdastr4325234324sdfds")
        )
        transaction = Transaction.create!(user: user, tx_date: DateTime.now)
        account = Account.create!(user: user, name: 'Test Account 2', account_type: 'Expense')

        expect {
          # Bypass Rails validation to test DB constraint
          ActiveRecord::Base.connection.execute(
            "INSERT INTO transaction_entries (transaction_id, account_id, debit_amount, credit_amount, created_at, updated_at)
             VALUES (#{transaction.id}, #{account.id}, NULL, NULL, NOW(), NOW())"
          )
        }.to raise_error(ActiveRecord::StatementInvalid, /one_amount_required/)
      end
    end

    context "when debit amount is negative" do
      it "raises database constraint error" do
        user = User.create!(
          username: 'testuser3',
          email: 'test3@example.com',
          password: 'password',
          salt: 'asdasdastr4325234324sdfds',
          crypted_password: Sorcery::CryptoProviders::BCrypt.encrypt("secret", "asdasdastr4325234324sdfds")
        )
        transaction = Transaction.create!(user: user, tx_date: DateTime.now)
        account = Account.create!(user: user, name: 'Test Account 3', account_type: 'Expense')

        expect {
          # Bypass Rails validation to test DB constraint
          ActiveRecord::Base.connection.execute(
            "INSERT INTO transaction_entries (transaction_id, account_id, debit_amount, credit_amount, created_at, updated_at)
             VALUES (#{transaction.id}, #{account.id}, -50, NULL, NOW(), NOW())"
          )
        }.to raise_error(ActiveRecord::StatementInvalid, /debit_non_negative/)
      end
    end

    context "when credit amount is negative" do
      it "raises database constraint error" do
        user = User.create!(
          username: 'testuser4',
          email: 'test4@example.com',
          password: 'password',
          salt: 'asdasdastr4325234324sdfds',
          crypted_password: Sorcery::CryptoProviders::BCrypt.encrypt("secret", "asdasdastr4325234324sdfds")
        )
        transaction = Transaction.create!(user: user, tx_date: DateTime.now)
        account = Account.create!(user: user, name: 'Test Account 4', account_type: 'Expense')

        expect {
          # Bypass Rails validation to test DB constraint
          ActiveRecord::Base.connection.execute(
            "INSERT INTO transaction_entries (transaction_id, account_id, debit_amount, credit_amount, created_at, updated_at)
             VALUES (#{transaction.id}, #{account.id}, NULL, -50, NOW(), NOW())"
          )
        }.to raise_error(ActiveRecord::StatementInvalid, /credit_non_negative/)
      end
    end
  end
end
