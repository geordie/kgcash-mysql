class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.string :name
      t.text :description

      t.timestamps
    end

    create_table :accounts_users do |t|
      t.belongs_to :account
      t.belongs_to :user
    end
  end
end
