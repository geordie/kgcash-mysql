class CategoriesController < ApplicationController

	def index

		@user = current_user
		@categories = @user.sortedCategories

		respond_to do |format|
			format.html #index.html.erb
			format.json {render json: @categories }
		end

	end

end
