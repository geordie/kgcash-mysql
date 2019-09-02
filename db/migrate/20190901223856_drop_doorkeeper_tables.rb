class DropDoorkeeperTables < ActiveRecord::Migration[4.2]
  def change
      drop_table :oauth_access_grants
      drop_table :oauth_access_tokens
      drop_table :oauth_applications
  end
end
