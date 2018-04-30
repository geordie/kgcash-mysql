class ChangeUsernameContraint < ActiveRecord::Migration[4.2]
  def change
      change_column :users, :username, :string, :null => true
  end
end
