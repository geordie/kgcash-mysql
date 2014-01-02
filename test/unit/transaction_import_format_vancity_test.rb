require 'test_helper'

class TransactionImportFormatVancityTester < ActiveSupport::TestCase

	test "Parse the right details out of a Vancity transaction" do
		@csvLine = '000000659243-004-Z    -00001,10-Dec-2013,"DIRECT BILL PAYMENT          ROYAL BANK VISA # 4290                                    Confirmation #0000000524234",,517.00,,3922.38'
		@transactionFormatter = TransactionImportFormatVancity.new
		@transaction = @transactionFormatter.buildTransaction( @csvLine, 1 )
		assert @transaction.details == 'ROYAL BANK VISA # 4290 Confirmation #0000000524234'
	end

	test "Parse the cheque # out of a Vancity transaction" do 
		@csvLine = '000000659243-004-Z    -00001,04-Nov-2013,"CHEQUE # 127                                                                          ",127,85.00,,5981.41'
		@transactionFormatter = TransactionImportFormatVancity.new
		@transaction = @transactionFormatter.buildTransaction( @csvLine, 1 )
		assert @transaction.details == 'CHEQUE # 127'
	end
end