class BudgetCategoriesController < ApplicationController
	# GET /budgets/1/categories
	# GET /budgets/1/categories.json
	def index
		@user = current_user
		@budget = @user.budgets.find(params[:budget_id])

		@budget_categories = BudgetCategory.includes(:account).where(budget_id: params[:budget_id]).where.not(account: nil)

		respond_to do |format|
			format.html # index.html.erb
			format.json { @budget_categories }
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

		respond_to do |format|
			if @budget_category.update_attributes(budget_category_params)
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
		@account = @budget.sortedAccounts

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

	private

	def budget_category_params
		params.require(:budget_category).permit(:account, :amount, :period, :account_id, :budget_id)
	end

end
