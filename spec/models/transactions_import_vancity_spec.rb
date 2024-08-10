RSpec.describe TransactionImportFormatVancity, type: :model do
  let(:transaction_formatter) { TransactionImportFormatVancity.new }

  describe 'Parsing Vancity transactions' do
    it 'parses the right details out of a Vancity transaction' do
      csv_line = '000000659243-004-Z    -00001,10-Dec-2013,"DIRECT BILL PAYMENT          ROYAL BANK VISA # 4290                                    Confirmation #0000000524234",,517.00,,3922.38'
      transaction = transaction_formatter.buildTransaction(csv_line, 1)
      expect(transaction.details).to eq('ROYAL BANK VISA # 4290 Confirmation #0000000524234')
    end

    it 'parses the cheque number out of a Vancity transaction' do
      csv_line = '000000659243-004-Z    -00001,04-Nov-2013,"CHEQUE # 127                                                                          ",127,85.00,,5981.41'
      transaction = transaction_formatter.buildTransaction(csv_line, 1)
      expect(transaction.details).to eq('CHEQUE # 127')
    end

    it 'hashes two transactions that are really close together differently' do
      csv_line1 = '000000659243-004-Z    -00001,31-Dec-2013,"TRANSFER FROM                NON-REDEEMABLE # 5                                       ",,,6.75,3070.01'
      csv_line2 = '000000659243-004-Z    -00001,31-Dec-2013,"TRANSFER2 FROM                NON-REDEEMABLE # 4                                       ",,,6.75,3063.26'
      transaction1 = transaction_formatter.buildTransaction(csv_line1, 1)
      transaction2 = transaction_formatter.buildTransaction(csv_line2, 1)
      expect(transaction1.tx_hash).not_to eq(transaction2.tx_hash), "Hashes should be different: #{transaction1.tx_hash}, #{transaction2.tx_hash}"
    end
  end
end