require 'date'
require 'digest/md5'

class TransactionImport
  # switch to ActiveModel::Model in Rails 4
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_accessor :file
  attr_accessor :account_id

  $txTypeDict = {"DIRECT TRANSFER FROM" => "Transfer From",
    "DIRECT TRANSFER TO" => "Transfer To",
    "ATM CASH WITHDRAWAL" => "ATM Withdrawl",
    "DIRECT BILL PAYMENT" => "Bill",
    "PAYROLL DEPOSIT" =>  "Payroll",
    "POINT OF SALE PURCHASE" => "Point of Sale",
    "ACCOUNT SERVICE CHARGE" => "Service Charge",
    "DIRECT DEPOSIT" =>  "Deposit"
  }

  $txCatDict = { "STONGS" => 2,
    "CHEVRON" => 4,
    "DIALOG" => 24,
    "FORTISBC" => 3,
    "SHAW" => 3,
    "SHOPPERS" => 6,
    "BC HYDRO" => 3,
    "MSP RSBC" => 7,
    "ROYAL VANCOUVER YACHT" => 18,
    "VAN LAWN" => 9,
    "THE HEIGHTS" => 2,
    "CANADA SAFEW" => 2
  }

  def initialize(attributes = {})
    unless attributes.nil?
      attributes.each { |name, value| send("#{name}=", value) }
    end
  end

  def persisted?
    false
  end

  def save

    if account_id.nil?
      errors.add :base, "Please select an account for the transactions being imported"
      return false
    end

    if file.nil?
      errors.add :base, "Please select a file to to import"
      return false
    end
    contents = file.read

    contents.split("\n").each_with_index do |csvline, idx|
      fields = csvline.split(',')
      # field[0]: account
      # field[3]: cheque #
      # field[6]: balance

      sDate = fields[1]
      date = DateTime.strptime(sDate,'%d-%b-%Y')
      sDate = date.strftime( '%y-%m-%d' )
      
      descParts = parseDescription(fields[2])
      type = descParts[0]
      desc = descParts[1]

      debit = fields[4].length > 0 ? fields[4] : "0"
      credit = fields[5].length > 0 ? fields[5] : "0"

      cat = 27

      $txCatDict.each_key do |item|
          if !desc.index(item.to_s).nil?
              cat = $txCatDict[item].to_s
              break
          end
      end

      @transaction = Transaction.create(
          :tx_date => date,
          :posting_date => date,
          :user_id => 1,
          :debit => debit,
          :credit => credit,
          :tx_type => type,
          :details => desc,
          :category_id => cat,
          :account_id => account_id
        )

      if @transaction.valid?
          @transaction.save!
      else
        @transaction.errors.full_messages.each do |message|
           errors.add :base, "Row #{idx+1}: #{message}"
        end
      end
      
    end
    errors.count == 0
  end

  def parseDescription( desc )
    parts = desc.split(" " * 7)
    type = parts[0].strip

    if $txTypeDict.has_key?( type )
        parts[0] = txTypeDict[ type ]
    else
        parts[0] = type.downcase
    end

    if parts.length > 2
        parts[1] = parts[1].strip + " " + parts[2].strip
    end
    
    parts[0] = parts[0].gsub( "\"", "")
    parts.delete("")
    parts[1] = parts[1].gsub( "\"", "").strip
    parts[0,2]
  end

  def imported_transactions
    @imported_transactions ||= load_imported_transactions
  end

  def load_imported_transactions
    spreadsheet = open_spreadsheet
    header = spreadsheet.row(1)
    (2..spreadsheet.last_row).map do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]
      transaction = Product.find_by_id(row["id"]) || Product.new
      transaction.attributes = row.to_hash.slice(*Product.accessible_attributes)
      transaction
    end
  end

  def open_spreadsheet
    case File.extname(file.original_filename)
    when ".csv" then Csv.new(file.path, nil, :ignore)
    when ".xls" then Excel.new(file.path, nil, :ignore)
    when ".xlsx" then Excelx.new(file.path, nil, :ignore)
    else raise "Unknown file type: #{file.original_filename}"
    end
  end
end
