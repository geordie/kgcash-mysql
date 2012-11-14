class Budget < ActiveRecord::Base
  belongs_to :user
  has_many :categories, :through => :budget_categories
end
