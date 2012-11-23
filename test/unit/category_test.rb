require 'test_helper'

class CategoryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "category will not save without a name" do
    category = categories(:empty)
    assert !category.save 
  end

  test "category will not save without name longer than 3 characers" do
    category = categories(:shortName)
    assert !category.save
  end

  test "category will save with valid name" do
    category = categories(:noDesc)
    assert category.save
  end

  test "category will save with name and desc" do
    category = categories(:one)
    assert category.save
  end
end
