require 'digest/md5'
require 'doorkeeper'

class Transaction < ActiveRecord::Base
  
  validates_uniqueness_of :tx_hash
  
  belongs_to :category
  belongs_to :user

  before_save :build_hash
  
  def build_hash
  	self.tx_hash = Digest::MD5.hexdigest( self.tx_date.to_s + 
  		(self.details or '')  + 
  		(self.debit.to_s or '') + 
  		(self.credit.to_s or '') )
    #TODO - generate unique transaction hash
  end

end
