require 'digest/md5'
require 'doorkeeper'

class Transaction < ActiveRecord::Base
  
  validates_uniqueness_of :tx_hash
  
  belongs_to :category
  belongs_to :user

  before_save :build_hash

  scope :by_year, lambda { |year| where('tx_date >= ? AND tx_date < ?', Date.new( year,1,1) , Date.new( year + 1,1,1)) }
  
  scope :by_month_year, lambda { |month, year| where( 'tx_date >= ? AND tx_date < ?', 
          Date.new(year,month,1), 
          month < 12 ? Date.new(year, month+1, 1 ) : Date.new(year+1,1,1) )
    }

  scope :by_category, lambda { |category_id| where("category_id = ?", category_id) unless category_id.nil? }
  
  def build_hash
  	self.tx_hash = Digest::MD5.hexdigest( self.tx_date.to_s + 
  		(self.details or '')  + 
  		(self.debit.to_s or '') + 
  		(self.credit.to_s or '') )
    #TODO - generate unique transaction hash
  end

end
