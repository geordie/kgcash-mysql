class CategoriesController < ApplicationController

	def index

		@user = current_user
		@categories = @user.accounts

		respond_to do |format|
			format.html #index.html.erb
			format.json {render json: @categories }
		end

	end

	def edit
		@user = current_user
		@account = @user.accounts.find(params[:id])
	end

	def update
		@account = Account.find(params[:id])

		respond_to do |format|
			if @account.update_attributes(account_params)
				format.html { redirect_to categories_path, notice: 'Account was successfully updated.' }
				format.json { respond_with_bip(@account) }
				format.js {render :nothing => true }
			else
				format.html { render action: "edit" }
				format.json { render json: @account.errors, status: :unprocessable_entity }
			end
		end
	end

	private

	def account_params
		params.require(:account).permit(:name, :description, :account_type )
	end

end
