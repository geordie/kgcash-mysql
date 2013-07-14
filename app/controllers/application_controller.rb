class ApplicationController < ActionController::Base
  before_filter :require_login
  protect_from_forgery

  protected
  def not_authenticated
  	if request.format.html?
    	redirect_to login_path, :alert => "Please login"
    end
  end
end
