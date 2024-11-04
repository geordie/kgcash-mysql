class Note < ApplicationRecord
  belongs_to :related_transaction, class_name: 'Transaction', optional: true
  belongs_to :user

  validates :note_text, presence: true
  validates :amount, numericality: true
  validates :user, presence: true
end
