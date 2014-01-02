require 'test_helper'

class TransactionImportFormatVancityTester < ActiveSupport::TestCase

	test "Correct parsing of a standard RBC Visa CSV item" do
		@csvLine = 'Visa,4.51224E+15,11/26/2013,,CAR2GO 855-454-1002 BC,,-$14.47,'
		@transactionFormatter = TransactionImportFormatRbcVisa.new
		@transaction = @transactionFormatter.buildTransaction( @csvLine, 1 )
		assert_equal @transaction.details, 'CAR2GO 855-454-1002 BC', "Incorrect transaction details: #{@transaction.details}"
		assert_equal @transaction.credit, 0, "Incorrect transaction credit amount: #{@transaction.credit}"
		assert_equal @transaction.debit, 14.47, "Incorrect transaction debit amount: #{@transaction.debit}"
	end

end