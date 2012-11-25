# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20121120073201) do

  create_table "budget_categories", :force => true do |t|
    t.decimal  "amount",      :precision => 10, :scale => 0
    t.string   "period"
    t.integer  "budget_id"
    t.integer  "category_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "budget_categories", ["budget_id"], :name => "index_budget_categories_on_budget_id"
  add_index "budget_categories", ["category_id"], :name => "index_budget_categories_on_category_id"

  create_table "budgets", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "budgets", ["user_id"], :name => "index_budgets_on_user_id"

  create_table "categories", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transactions", :force => true do |t|
    t.string   "tx_hash"
    t.datetime "tx_date"
    t.decimal  "debit",       :precision => 10, :scale => 0
    t.decimal  "credit",      :precision => 10, :scale => 0
    t.string   "tx_type"
    t.string   "details"
    t.string   "notes"
    t.integer  "category_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "transactions", ["category_id"], :name => "index_transactions_on_category_id"
  add_index "transactions", ["user_id"], :name => "index_transactions_on_user_id"
  add_index "transactions", ["tx_hash"], :unique => true, :name => "index_transactions_on_hash_unique"

  create_table "users", :force => true do |t|
    t.string   "username",         :null => false
    t.string   "email"
    t.string   "crypted_password"
    t.string   "salt"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
