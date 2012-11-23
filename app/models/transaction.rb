class Transaction < ActiveRecord::Base
  
  validates_uniqueness_of :hash
  
  belongs_to :category
  belongs_to :user
end
