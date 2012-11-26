class User < ActiveRecord::Base
  authenticates_with_sorcery!
  attr_accessible :username, :email, :password, :password_confirmation

  validates_length_of :password, :minimum => 5, :message => "password must be at least 5 characters long", :if => :password
  validates_confirmation_of :password, :message => "should match confirmation", :if => :password
  
  has_many :budgets
  has_many :transactions
  has_many :categories

  def category_selector

  	#Build an array of pairs as expected by a form dropdown
  	results = Array.new

  	categories.each do |cat|
  		rec = Array.new
  		rec.push cat.name
  		rec.push cat.id
  		results.push rec 
  	end
   	return results
  end
end
