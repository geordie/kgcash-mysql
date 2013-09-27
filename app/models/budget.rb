class Budget < ActiveRecord::Base
  belongs_to :user
  has_many :budget_categories, :dependent => :delete_all
  has_many :categories, :through => :budget_categories

  def sortedCategories( includeAll = false )
  	@categories = self.categories.sort!{|a,b| a.name.downcase <=> b.name.downcase }
  	if includeAll
  		@bcAll = Category.new
  		@bcAll.name = "All"
  		@bcAll.id = nil
  		@categories = [@bcAll] + @categories 
  	end
  	return @categories
  end
end
