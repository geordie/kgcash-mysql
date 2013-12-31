require 'date'
require 'digest/md5'

class TransactionImport
  # switch to ActiveModel::Model in Rails 4
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_accessor :file
  attr_accessor :account_id

  def initialize(attributes = {})
    unless attributes.nil?
      attributes.each { |name, value| send("#{name}=", value) }
    end
  end

  def persisted?
    false
  end

  def save( transaction_import_format )

    if account_id.nil?
      errors.add :base, "Please select an account for the transactions being imported"
      return false
    end

    if file.nil?
      errors.add :base, "Please select a file to to import"
      return false
    end

    if( transaction_import_format.nil? )
      errors.add :base, "Please specify an import file format"
      return false
    end

    # Read file
    contents = file.read

    # Process each line
    contents.split("\n").each_with_index do |csvline, idx|

      @transaction = transaction_import_format.buildTransaction( csvline, account_id )

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

end
