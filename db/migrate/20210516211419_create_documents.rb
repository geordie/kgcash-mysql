class CreateDocuments < ActiveRecord::Migration[5.2]
  def change
    create_table :documents do |t|
      t.string :name

      t.timestamps
    end

    create_table :documents_users, id: false do |t|
      t.belongs_to :user
      t.belongs_to :document
    end
    
  end
end
