class BudgetCategoriesController < ApplicationController
  # GET /budgets/1/categories
  # GET /budgets/1/categories.json
  def index
    @user = current_user
    @budget = @user.budgets.find(params[:budget_id])
    @budget_categories = @budget.budget_categories

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @budget_categories }
    end
  end

  # GET /budgets/1/categories/1
  # GET /budgets/1/categories/1.json
  def show

    @user = current_user
    @budget = @user.budgets.find(params[:budget_id])
    @budget_category = @budget.budget_categories.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @budget_category }
    end
  end

 # GET /budgets/1/categories/1/edit
  def edit
    @user = current_user
    @budget = @user.budgets.find(params[:budget_id])
    @budget_category = @budget.budget_categories.find(params[:id])
    @categories = Category.where(:user_id => @user)
  end


  def create
    @user = current_user
    @budget = @user.budgets.find(params[:budget_id])
    @budget_category = @budget.budget_categories.new


    respond_to do |format|
      if @budget_category.save
        format.html { redirect_to(:budget_categories, :notice => 'Budget Category was successfully created for user.') }
        format.json { render json: @budget_category, status: :created, location: @budget_category }
      else
        format.html { render action: "new" }
        format.json { render json: @buget_category.errors, status: :unprocessable_entity }
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
        format.html { redirect_to :action => 'index', notice: 'Budget Category was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @budget_category.errors, status: :unprocessable_entity }
      end
    end
  end


  # GET /budgets/4/budget_categories/new
  # GET /budgets/4/budget_categories/new.json
  def new

    @user = current_user
    @budget = @user.budgets.find(params[:budget_id])

    @budget_category = @budget.budget_categories.new

    @budget.budget_categories << @budget_category
    @categories = Category.where(:user_id => @user)

    respond_to do |format|
      format.html
      format.json { render json: @budget_category }
    end
  end

  # DELETE /users/1/budgets/2
  # DELETE /users/1/budgets/2.json
  def destroy
    @user = current_user
    @budget = @user.budgets.find(params[:budget_id])
    
    @budget_category = @budget.budget_categories.find(params[:id])
    
    @budget_category.destroy

    respond_to do |format|
      format.html { redirect_to :action => 'index' }
      format.json { head :ok }
    end
  end

end
