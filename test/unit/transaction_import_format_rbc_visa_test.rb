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

	test "Correct amount when amount is quoted" do
		@csvLine = 'Visa,4.51224E+15,12/18/2013,,PAYMENT - THANK YOU / PAIEMENT - MERCI,,"$1,050.00",'
		@transactionFormatter = TransactionImportFormatRbcVisa.new
		@transaction = @transactionFormatter.buildTransaction( @csvLine, 1 )
		assert_equal @transaction.details, 'PAYMENT - THANK YOU / PAIEMENT - MERCI', "Incorrect transaction details: #{@transaction.details}"
		assert_equal @transaction.credit, 1050, "Incorrect transaction credit amount: #{@transaction.credit}"
		assert_equal @transaction.debit, 0, "Incorrect transaction debit amount: #{@transaction.debit}"
	end


end