require 'test_helper'

class TransactionTest < ActiveSupport::TestCase

	test "transaction save same hash twice" do
		t1 = transactions(:tx_1)

		t3 = Transaction.new
		t3.tx_hash = t1.tx_hash
		t3.valid?

		assert_not_nil t3.errors[:hash]
	end

	test "Access user transactions" do
		user1 = users(:one)

		txs = user1.transactions

		assert txs.count == 3
	end

	test "Transaction filters" do
		user1 = users(:one)

		txs = user1.transactions.in_year(2012)
		assert txs.count == 3, "Actual: " + txs.count.to_s

		txs = user1.transactions.in_month_year(11,2012)
		assert txs.count == 2, "Actual: " + txs.count.to_s

		txs = user1.transactions.in_year(2013)
		assert txs.count == 0, "Actual: " + txs.count.to_s

		txs = user1.transactions.in_month_year(1,2012)
		assert txs.count == 0, "Actual: " + txs.count.to_s

		txs = user1.transactions.by_months_in_year(2012)
		assert txs.length == 2, "ACTUAL: " + txs.count.to_s

		txs = user1.transactions.by_days_in_month(11, 2012)
		assert txs.length == 1, "ACTUAL: " + txs.count.to_s

	end

end
