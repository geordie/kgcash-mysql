class Budget < ActiveRecord::Base
  belongs_to :user
  has_many :budget_categories, :dependent => :delete_all
  has_many :categories, :through => :budget_categories

  def sortedCategories
  	return self.categories.sort!{|a,b| a.name.downcase <=> b.name.downcase }
  end
end
