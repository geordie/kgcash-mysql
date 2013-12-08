class User < ActiveRecord::Base
  authenticates_with_sorcery!
  attr_accessible :username, :email, :password, :password_confirmation

  validates_length_of :password, :minimum => 5, :message => "password must be at least 5 characters long", :if => :password
  validates_confirmation_of :password, :message => "should match confirmation", :if => :password
  
  has_many :budgets
  has_many :transactions
  has_many :categories

  has_and_belongs_to_many :accounts

  def category_selector

  	#Build an array of pairs as expected by a form dropdown
  	results = Array.new

  	categories.each do |cat|
  		rec = Array.new
  		rec.push cat.name
  		rec.push cat.id
  		results.push rec 
  	end
   	return results.sort
  end

  def sortedCategories
    return categories.sort!{|a,b| a.name.downcase <=> b.name.downcase }
  end

  def sortedAccounts
    @accounts = accounts.sort!{|a,b| a.name.downcase <=> b.name.downcase }
    @undefined = Account.new
    @undefined.id = 0
    @undefined.name = 'none'
    @accounts.unshift @undefined

    return @accounts
  end

  def account_selector

    #Build an array of pairs as expected by a form dropdown
    results = Array.new

    accounts.each do |acct|
      rec = Array.new
      rec.push acct.name
      rec.push acct.id
      results.push rec 
    end
    return results.sort
  end

end
