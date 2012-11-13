class BudgetsController < ApplicationController
  # GET /users/1/budgets
  # GET /users/1/budgets.json
  def index
    @user = User.find(params[:user_id])
    @budgets = @user.budgets

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @budgets }
    end
  end

  # GET /users/1/budgets/2
  # GET /users/1/budgets/2.json
  def show
    @user = User.find(params[:user_id])
    @budget = @user.budgets.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @budget }
    end
  end


  def create
    @user = User.find(params[:user_id])
    @budget = @user.budgets.create(params[:budget])

    respond_to do |format|
      if @user.save
        format.html { redirect_to(:users, :notice => 'Budget was successfully created for user.') }
        format.json { render json: @user, status: :created, location: @user }
      else
        format.html { render action: "new" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /users/1/budgets/new
  # GET /users/1/budgets/new.json
  def new

    @user = User.find(params[:user_id])
    @budget = @user.budgets.build

    respond_to do |format|
      if @user.save
        format.html { redirect_to(:users, :notice => 'Budget was successfully created for user.') }
        format.json { render json: @user, status: :created, location: @user }
      else
        format.html { render action: "new" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
 
  end


end
