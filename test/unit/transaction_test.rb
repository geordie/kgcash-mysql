require 'test_helper'

class TransactionTest < ActiveSupport::TestCase
  
  test "transaction save same hash twice" do
  	t1 = transactions(:one)

  	t3 = Transaction.new
  	t3.hash = t1.hash
  	t3.valid?

  	assert_not_nil t3.errors[:hash]

  end

end
