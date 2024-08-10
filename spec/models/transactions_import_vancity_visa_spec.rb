RSpec.describe TransactionImportFormatVancityVisa, type: :model do
  let(:transaction_formatter) { TransactionImportFormatVancityVisa.new }

  describe 'Parsing Vancity Visa transactions' do
    it 'parses the correct details of a standard Vancity Visa CSV item' do
      csv_line = '02/01/2013,03/01/2013,$178.09,"RESORT RESERVATIONS WHIST","BURNABY",BC,0000000000, "74064493002820133211288",D,7299'
      transaction = transaction_formatter.buildTransaction(csv_line, 1)
      expect(transaction.details).to eq('RESORT RESERVATIONS WHIST BURNABY BC')
      expect(transaction.credit).to eq(178.09)
      expect(transaction.debit).to be_nil
    end

    it 'parses the correct details of a standard Vancity Visa CSV credit item' do
      csv_line = '02/01/2013,03/01/2013,($178.08),"RESORT RESERVATIONS WHIST","BURNABY",BC,0000000000, "74064493002820133211288",C,7299'
      transaction = transaction_formatter.buildTransaction(csv_line, 1)
      expect(transaction.details).to eq('RESORT RESERVATIONS WHIST BURNABY BC')
      expect(transaction.credit).to be_nil
      expect(transaction.debit).to eq(178.08)
    end
  end
end