class Transaction < ActiveRecord::Base
  
  validates_uniqueness_of :tx_hash
  
  belongs_to :category
  belongs_to :user

  before_save :build_hash
  
  def build_hash
    #TODO - generate unique transaction hash
  end

end
