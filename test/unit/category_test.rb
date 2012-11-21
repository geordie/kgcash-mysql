require 'test_helper'

class CategoryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "category will not save without a name" do
    category = Category.new
    assert !category.save 
  end

  test "category will not save without name longer than 3 characers" do
    category = Category.new
    category.name = "ab"
    assert !category.save
  end

  test "category will save with valid name" do
    category = Category.new
    category.name = "Groceries"
    assert category.save
  end

  test "category will save with name and desc" do
    category = Category.new
    category.name = "Salary"
    category.description = "Money earned"
    assert category.save
  end
end
