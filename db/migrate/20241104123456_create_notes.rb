class CreateNotes < ActiveRecord::Migration[6.1]
  def change
    create_table :notes do |t|
      t.text :note_text, null: false
      t.decimal :amount, null: false, precision: 10, scale: 2
      t.references :transaction, null: true

      t.timestamps
    end
  end
end
