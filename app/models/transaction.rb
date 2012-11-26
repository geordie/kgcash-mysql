class Transaction < ActiveRecord::Base
  
  validates_uniqueness_of :tx_hash
  
  belongs_to :category
  belongs_to :user

  before_save :default_values
  
  def default_values
    #TODO - generate unique transaction hash
  end

  def self.category_selector
  	results = Array.new

  	Category.select( "id, name" ).each do |cat|
  		rec = Array.new
  		rec.push cat.name
  		rec.push cat.id
  		results.push rec 
  	end
   	return results
  end

end
