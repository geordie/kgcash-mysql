class TransactionEntry < ApplicationRecord
  belongs_to :parent_transaction, class_name: 'Transaction', foreign_key: 'transaction_id'
  belongs_to :account

  validates_presence_of :parent_transaction, :account
  validate :exactly_one_amount
  validate :amount_positive

  # Scopes for querying
  scope :debits, -> { where.not(debit_amount: nil) }
  scope :credits, -> { where.not(credit_amount: nil) }
  scope :for_account, ->(account) { where(account_id: account.id) }
  scope :for_account_type, ->(type) {
    joins(:account).where(accounts: { account_type: type })
  }
  scope :in_period, ->(start_date, end_date) {
    joins(:parent_transaction).where(transactions: { tx_date: start_date..end_date })
  }

  # Helper methods
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
