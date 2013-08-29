class Category < ActiveRecord::Base

  belongs_to :user
  has_many :budget_categories
  has_many :budgets, :through => :budget_categories

  validates :name, :presence => true,
                    :length => { :minimum => 3 }

end
