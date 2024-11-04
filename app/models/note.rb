class Note < ApplicationRecord
  belongs_to :related_transaction, class_name: 'Transaction', optional: true

  validates :note_text, presence: true
  validates :amount, numericality: true
end
