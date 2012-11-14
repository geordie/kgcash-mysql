class Category < ActiveRecord::Base

  has_many :budgets, :through => :budget_categories
  
  validates :name, :presence => true,
                    :length => { :minimum => 3 }
end
