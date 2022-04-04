class CategoriesController < ApplicationController

	def index
		@user = current_user
		@categories = @user.sortedAccounts

		respond_to do |format|
			format.html #index.html.erb
			format.json {render json: @categories }
		end

	end

	def edit
		@user = current_user
		@account = @user.accounts.find(params[:id])
	end

	def create
		@user = current_user
		if @user == nil
			@user = User.last
		end

		@account = @user.accounts.create(category_params)

		respond_to do |format|
			if @account.save
				format.html { redirect_to(categories_path, :notice => 'Category was successfully created for user.') }
				format.json { render json: @account, status: :created, location: @account }
			else
				format.html { render action: "new" }
				format.json { render json: @account.errors, status: :unprocessable_entity }
			end
		end
	end

	def show
		@user = current_user
		if @user == nil
			@user = User.last
		end

		@account = @user.accounts.find(params[:id])

		respond_to do |format|
			format.html #show.html.erb
			format.json {render json: @account}
		end
	end

	def update
		@account = Account.find(params[:id])

		respond_to do |format|
			if @account.update(category_params)
				format.html { redirect_to categories_path, notice: 'Account was successfully updated.' }
				format.json { respond_with_bip(@account) }
				format.js {render :nothing => true }
			else
				format.html { render action: "edit" }
				format.json { render json: @account.errors, status: :unprocessable_entity }
			end
		end
	end

	def new
		@user = current_user
		@account = Account.new

		respond_to do |format|
			format.html # new.html.erb
			format.json {render json: @account}
		end
	end

	def destroy
		@user = current_user
		@account = @user.accounts.find(params[:id])
		@account.destroy

		respond_to do |format|
			format.html { redirect_to categories_path }
			format.js   { render :nothing => true }
			format.json { head :ok }
		end
	end

	private

	def category_params
		params.require(:category).permit(:name, :description, :account_type )
	end

end
