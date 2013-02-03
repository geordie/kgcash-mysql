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

  	@transactions = @user.transactions.select("transactions.*, categories.name AS category_name").by_month_year( @month, @year).joins(:category).order("tx_date DESC").limit(20)

    @categories = Hash.new
    @transactions.each do |t|

      @amount = (t.credit.nil? ? 0 : t.credit) + (t.debit.nil? ? 0 : t.debit)

      if @categories.has_key? t.category_name
        @categories[ t.category_name ] += @amount
      else
        @categories[ t.category_name ] = @amount
      end

    end

    # Use this format becaus it's nice for D3 JSON - maybe should do this client side instead, but whatev
    @category_amounts = Array.new
    @categories.each_pair do |key,val|
      @category_amounts.push( CategoryAmount.new( key, val ))
    end

  	respond_to do |format|
  		format.html #index.html.erb
  		format.json {render json: @categories }
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