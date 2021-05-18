class DocumentsController < ApplicationController
	def index
		@user = current_user
		@documents = @user.documents

		respond_to do |format|
			format.html # index.html.erb
		end
	end

	def new
		@document = Document.new
	end

	def create
		@document = Document.new(document_params)
		@document.users<<current_user
	
		if @document.save
		  redirect_to @document
		else
		  render :new
		end
	end

	def show

		@user = current_user
		if @user == nil
			@user = User.last
		end
		@document = @user.documents.find(params[:id])

		respond_to do |format|
			format.html #show.html.erb
		end
	end

	private
		def document_params
			params.require(:document).permit(:name, :file)
		end
end
