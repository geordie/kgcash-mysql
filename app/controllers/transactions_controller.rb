class TransactionsController < ApplicationController
  
  def index
  	@user = current_user
  	@transactions = @user.transactions.order("tx_date DESC")

    dateStart = params[:start]
    dateEnd = params[:end] 

  	respond_to do |format|
  		format.html #index.html.erb
  		format.json {render json: @transactions }
  	end
  end

  def show
  	@user = current_user
  	@transaction = @user.transactions.find(params[:id])

  	respond_to do |format|
  		format.html #show.html.erb
  		format.json {render json: @transaction}
  	end
  end

  def edit
  	@user = current_user
  	@transaction = @user.transactions.find(params[:id])
    @categories = @user.category_selector
  end

  def create
    @user = current_user
    @transaction = @user.transactions.create(params[:transaction])

    respond_to do |format|
      if @transaction.save
        format.html { redirect_to(:users, :notice => 'Transaction was successfully created for user.') }
        format.json { render json: @transaction, status: :created, location: @user }
      else
        format.html { render action: "new" }
        format.json { render json: @transaction.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @transaction = Transaction.find(params[:id])

    respond_to do |format|
      if @transaction.update_attributes(params[:transaction])
        format.html { redirect_to :action => 'show', notice: 'Transaction was successfully updated yo.' }
        format.json { head :ok }
        format.js {render :nothing => true }
      else
        format.html { render action: "edit" }
        format.json { render json: @transaction.errors, status: :unprocessable_entity }
      end
    end
  end


  def new
  	@user = current_user
  	@transaction = Transaction.new
    @transaction.tx_date = DateTime.now
    @categories = @user.category_selector


  	@user.transactions << @transaction

  	respond_to do |format|
  		format.html # new.html.erb
  		format.json {render json: @transaction}
  	end
  end

  def destroy
    @user = current_user
    @transaction = @user.transactions.find(params[:id])
    @transaction.destroy

    respond_to do |format|
      format.html { redirect_to :action => 'index' }
      format.js   { render :nothing => true }
      format.json { head :ok }
    end
  end
end
