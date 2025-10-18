RSpec.describe TransactionImportFormatRbcVisa, type: :model do
  let(:transaction_formatter) { TransactionImportFormatRbcVisa.new }

  describe 'Parsing RBC Visa transactions' do
    it 'parses the correct details of a standard RBC Visa CSV item' do
      csv_line = 'Visa,4.51224E+15,11/26/2013,,CAR2GO 855-454-1002 BC,,-$14.47,'
      transaction = transaction_formatter.buildTransaction(csv_line, 1, 1)
      expect(transaction.details).to eq('CAR2GO 855-454-1002 BC')
      expect(transaction.credit).to eq(14.47)
      expect(transaction.debit).to be_nil
    end

    it 'parses the correct amount when the amount is quoted' do
      csv_line = 'Visa,4.51224E+15,12/18/2013,,PAYMENT - THANK YOU / PAIEMENT - MERCI,,"$1,050.00",'
      transaction = transaction_formatter.buildTransaction(csv_line, 1, 1)
      expect(transaction.details).to eq('PAYMENT - THANK YOU / PAIEMENT - MERCI')
      expect(transaction.credit).to be_nil
      expect(transaction.debit).to eq(1050.00)
    end
  end
end