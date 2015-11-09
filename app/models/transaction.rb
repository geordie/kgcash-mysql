require 'digest/md5'
require 'doorkeeper'

class Transaction < ActiveRecord::Base

  validates_uniqueness_of :tx_hash
  validates_presence_of :tx_date

  belongs_to :category
  belongs_to :user
  belongs_to :account

  before_save :ensure_hash

  before_validation :ensure_hash

	self.per_page = 50

  default_scope order('tx_date DESC')

  scope :in_year, lambda { |year| where('tx_date >= ? AND tx_date < ?', Date.new( year,1,1) , Date.new( year + 1,1,1)) }

  scope :in_month_year, lambda { |month, year| where( 'tx_date >= ? AND tx_date < ?',
          Date.new(year,month,1),
          month < 12 ? Date.new(year, month+1, 1 ) : Date.new(year+1,1,1) )
    }

  scope :in_category, lambda { |category_id| where("category_id = ?", category_id) unless category_id.nil? }

  scope :in_account, lambda { |account_id| where("account_id = ?", account_id) unless account_id.nil? }

  scope :in_range, lambda { |min, max| where("(debit >= ? AND debit <= ?) OR (credit >= ? AND credit <= ?)",
          min == 0 ? -10000000 : min,
          max == 0 ? 10000000 : max,
          min == 0 ? -10000000 : min,
          max == 0 ? 10000000 : max)}

  scope :by_months_in_year, lambda{ |year| in_year(year).select("MONTH(tx_date) as month, SUM(debit) as debit, SUM(credit) as credit").group( "MONTH(tx_date)") }

  scope :by_days_in_month, lambda{ |month, year| in_month_year(month,year).select("DAY(tx_date) as day, SUM(debit) as debit, SUM(credit) as credit").group("DAY(tx_date)")}

  def ensure_hash

    if self.tx_hash.to_s == ''
    	self.tx_hash = build_hash
    end

  end

  def build_hash
    return Digest::MD5.hexdigest( self.tx_date.to_s +
        (self.details or '')  +
        (self.debit.to_s or '') +
        (self.credit.to_s or '') )
  end

  def format_date
    @date = self.tx_date
    @date.strftime( '%d-%b-%Y')
  end

end
