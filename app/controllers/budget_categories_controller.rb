class BudgetCategoriesController < ApplicationController
  # GET /budgets/1/categories
  # GET /budgets/1/categories.json
  def index
    @budget = Budget.find(params[:budget_id])
    @budget_categories = BudgetCategory.includes(:category).where(:budget_id => @budget)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @budget_categories }
    end
  end

  # GET /users/1/budgets/2
  # GET /users/1/budgets/2.json
  def show
    @user = current_user
    @budget_category = BudgetCategory.includes(:category).find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @budget_category }
    end
  end

 # GET /budgets/1/categories/1/edit
  def edit
    @user = current_user
    @budget_category = BudgetCategory.find(params[:id])
    @categories = Category.where(:user_id => @user)
  end


  def create
    @user = current_user
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

  # PUT /budgets/1/categories/1
  # PUT /budgets/1/categories/1.json
  def update
    @budget_category = BudgetCategory.find(params[:id])

    @updateParams = params[:budget_category]

    #replace the returned category key with a category_id key so we can update properly
    if @updateParams.has_key?( 'category')
      @updateParams['category_id'] = @updateParams.delete('category');
    end

    respond_to do |format|
      if @budget_category.update_attributes(@updateParams)
        format.html { redirect_to :action => 'show', notice: 'Budget Category was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @budget_category.errors, status: :unprocessable_entity }
      end
    end
  end


  # GET /users/1/budgets/new
  # GET /users/1/budgets/new.json
  def new

    @user = current_user
    @budget = Budget.new

    @user.budgets << @budget

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @budget }
    end
  end

  # DELETE /users/1/budgets/2
  # DELETE /users/1/budgets/2.json
  def destroy
    @user = current_user
    @category = @user.budgets.find(params[:id])
    @category.destroy

    respond_to do |format|
      format.html { redirect_to :action => 'index' }
      format.json { head :ok }
    end
  end

end
