class ReportsController < ApplicationController
   
  doorkeeper_for :all, :if => lambda { current_user.nil? && request.format.json? } 
  
  def index
  	@user = current_user
    if @user == nil 
        @user = User.last
    end 
  	@transactions = @user.transactions.select("transactions.*, categories.name AS category_name").by_year(2011).joins(:category).order("tx_date DESC").limit(20)

    #TODO - Enable filtering by date range
    # dateStart = params Date.strptime([:start], "{ %Y, %m, %d }")
    # dateEnd = params[:end]

  	respond_to do |format|
  		format.html #index.html.erb
  		format.json {render json: @transactions }
  	end
  end

end