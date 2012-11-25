class TransactionsController < ApplicationController
  
  def index
  	@user = current_user
  	@transactions = @user.transactions

  	respond_to do |format|
  		format.html #index.html.erb
  		format.json {render json: @transations }
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
        format.html { redirect_to :action => 'show', notice: 'Transaction was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @transaction.errors, status: :unprocessable_entity }
      end
    end
  end


  def new
  	@user = current_user
  	@transaction = Transaction.new

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
      format.json { head :ok }
    end
  end
end
