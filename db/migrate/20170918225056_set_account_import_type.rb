class SetAccountImportType < ActiveRecord::Migration[4.2]
  def change
    UpdateAccount("Joint", "Vancity")
    UpdateAccount("Geordie Vancity", "Vancity")
    UpdateAccount("kt-visa", "RBC Visa")
    UpdateAccount("Geordie visa", "Vancity Visa")
  end

  private

  def UpdateAccount( name, import_type )

    acct = Account.find_by(name: name)
    if !acct.nil?
      acct.import_class = import_type
      acct.save()
    end

  end
end
