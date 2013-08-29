class Budget < ActiveRecord::Base
  belongs_to :user
  has_many :budget_categories, :dependent => :delete_all
  has_many :categories, :through => :budget_categories
end
