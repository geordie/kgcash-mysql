class BudgetsController < ApplicationController
	# GET /users/1/budgets
	# GET /users/1/budgets.json
	def index
		@user = current_user
		@budgets = @user.budgets

		respond_to do |format|
			format.html # index.html.erb
			format.json { render json: @budgets }
		end
	end

	# GET /users/1/budgets/2
	# GET /users/1/budgets/2.json
	def show
		@user = current_user
		@budget = @user.budgets.find(params[:id])
		@budget_categories = BudgetCategory.includes(:category).where(:budget_id => @budget.id)

		respond_to do |format|
			format.html # show.html.erb
			format.json { render json: @budget }
		end
	end

 # GET /users/1/edit
	def edit
		@user = current_user
		@budget = @user.budgets.find(params[:id])
	end


	def create
		@user = current_user
		@budget = @user.budgets.create(budget_params)

		respond_to do |format|
			if @budget.save
				format.html { redirect_to(:budgets, :notice => 'Budget was successfully created for user.') }
				format.json { render json: @user, status: :created, location: @user }
			else
				format.html { render action: "new" }
				format.json { render json: @user.errors, status: :unprocessable_entity }
			end
		end
	end

	# PUT /users/1/budgets/2
	# PUT /users/1/budgets/2.json
	def update
		@budget = Budget.find(params[:id])

		respond_to do |format|
			if @budget.update(budget_params)
				format.html { redirect_to :action => 'show', notice: 'Budget was successfully updated.' }
				format.json { head :ok }
			else
				format.html { render action: "edit" }
				format.json { render json: @budget.errors, status: :unprocessable_entity }
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
		@budget = @user.budgets.find(params[:id])
		@budget.destroy

		respond_to do |format|
			format.html { redirect_to :action => 'index' }
			format.json { head :ok }
		end
	end
end

private

def budget_params
	params.require(:budget).permit(:name, :description)
end
