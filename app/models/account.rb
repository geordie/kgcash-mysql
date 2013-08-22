class Account < ActiveRecord::Base
  attr_accessible :description, :name
  has_many :transactions
  has_and_belongs_to_many :users
end
