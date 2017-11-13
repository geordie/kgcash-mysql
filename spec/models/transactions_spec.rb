RSpec.describe Transaction, :type => :model do

  subject { described_class.new }

  describe ".format_date" do

    context "given November 22, 2017" do
      it "equals 2017-Nov-22" do
        subject.tx_date = Date.new(2017,11,22)
        expect(subject.format_date).to eql("22-Nov-2017")
      end
    end
  end
end
