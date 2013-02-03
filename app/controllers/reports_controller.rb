class ReportsController < ApplicationController
   
  doorkeeper_for :all, :if => lambda { current_user.nil? && request.format.json? } 
  
  def index
  	@user = current_user
    if @user == nil 
        @user = User.last
    end 

    #TODO - Enable filtering by date range
    time = Time.new
    @month = params.has_key?(:month) ? params[:month].to_i : time.month
    @year = params.has_key?(:year) ? params[:year].to_i : time.year

  	@transactions = @user.transactions.select("transactions.*, categories.name AS category_name")
      .by_month_year( @month, @year).joins(:category)

    @expense_categories = Hash.new
    

    @transactions.each do |t|

      next unless t.category.cat_type == "Expense" || t.category.cat_type.nil?

      @amount = (t.credit.nil? ? 0 : t.credit) + (t.debit.nil? ? 0 : t.debit)

      if @expense_categories.has_key? t.category_name
        @expense_categories[ t.category_name ] += @amount
      else
        @expense_categories[ t.category_name ] = @amount
      end

    end

    # Use this format because it's nice for D3 JSON - maybe should do this client side instead, but whatev
    @category_amounts = Array.new

    @expense_categories.each_pair do |key,val|
      @category_amounts.push( CategoryAmount.new( key, val ))
    end

  	respond_to do |format|
  		format.html #index.html.erb
  		format.json {render json: @expense_categories }
  	end
  end

end

class CategoryAmount
  attr_accessor :category, :amount

  def initialize(category, amount)
    @category = category
    @amount = amount
  end      
end