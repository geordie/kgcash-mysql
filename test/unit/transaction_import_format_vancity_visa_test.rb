require 'test_helper'

class TransactionImportFormatVancityTester < ActiveSupport::TestCase

	test "Correct parsing of a standard Vancity Visa CSV item" do
		@csvLine = '02/01/2013,03/01/2013,$178.08,"RESORT RESERVATIONS WHIST","BURNABY",BC,0000000000, "74064493002820133211288",D,7299'
		@transactionFormatter = TransactionImportFormatVancityVisa.new
		@transaction = @transactionFormatter.buildTransaction( @csvLine, 1 )
		assert_equal 'RESORT RESERVATIONS WHIST BURNABY BC', @transaction.details, "Incorrect transaction details: #{@transaction.details}"
		assert_equal 0, @transaction.credit, "Incorrect transaction credit amount: #{@transaction.credit}"
		assert_equal 178.08, @transaction.debit, "Incorrect transaction debit amount: #{@transaction.debit}"
	end

	test "Correct parsing of a standard Vancity Visa CSV credit item" do
		@csvLine = '02/01/2013,03/01/2013,($178.08),"RESORT RESERVATIONS WHIST","BURNABY",BC,0000000000, "74064493002820133211288",C,7299'
		@transactionFormatter = TransactionImportFormatVancityVisa.new
		@transaction = @transactionFormatter.buildTransaction( @csvLine, 1 )
		assert_equal 'RESORT RESERVATIONS WHIST BURNABY BC', @transaction.details, "Incorrect transaction details: #{@transaction.details}"
		assert_equal 178.08, @transaction.credit, "Incorrect transaction credit amount: #{@transaction.credit}"
		assert_equal 0, @transaction.debit, "Incorrect transaction debit amount: #{@transaction.debit}"
	end

end
