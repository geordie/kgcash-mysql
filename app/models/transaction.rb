class Transaction < ActiveRecord::Base
  
  validates_uniqueness_of :tx_hash
  
  belongs_to :category
  belongs_to :user

  before_save :default_values
  
  def default_values
    #TODO - generate unique transaction hash
  end

end
