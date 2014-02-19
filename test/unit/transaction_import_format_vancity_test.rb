require 'test_helper'

class TransactionImportFormatVancityTester < ActiveSupport::TestCase

	test "Parse the right details out of a Vancity transaction" do
		@csvLine = '000000659243-004-Z    -00001,10-Dec-2013,"DIRECT BILL PAYMENT          ROYAL BANK VISA # 4290                                    Confirmation #0000000524234",,517.00,,3922.38'
		@transactionFormatter = TransactionImportFormatVancity.new
		@transaction = @transactionFormatter.buildTransaction( @csvLine, 1 )
		assert_equal 'ROYAL BANK VISA # 4290 Confirmation #0000000524234', @transaction.details
	end

	test "Parse the cheque # out of a Vancity transaction" do 
		@csvLine = '000000659243-004-Z    -00001,04-Nov-2013,"CHEQUE # 127                                                                          ",127,85.00,,5981.41'
		@transactionFormatter = TransactionImportFormatVancity.new
		@transaction = @transactionFormatter.buildTransaction( @csvLine, 1 )
		assert @transaction.details == 'CHEQUE # 127'
	end

	test "Hashing two transactions that are really close together" do
		@csvLine1 = '000000659243-004-Z    -00001,31-Dec-2013,"TRANSFER FROM                NON-REDEEMABLE # 5                                       ",,,6.75,3070.01'
		@csvLine2 = '000000659243-004-Z    -00001,31-Dec-2013,"TRANSFER2 FROM                NON-REDEEMABLE # 4                                       ",,,6.75,3063.26'
		@transactionFormatter = TransactionImportFormatVancity.new
		@transaction1 = @transactionFormatter.buildTransaction( @csvLine1, 1 )
		@transaction2 = @transactionFormatter.buildTransaction( @csvLine2, 1 )
		assert_not_equal @transaction1.tx_hash, @transaction2.tx_hash, "Hashes should be different: #{@transaction1.tx_hash}, #{@transaction2.tx_hash}"
	end
end