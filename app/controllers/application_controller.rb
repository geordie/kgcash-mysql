class ApplicationController < ActionController::Base
  before_action :require_login
  protect_from_forgery

  protected
  def not_authenticated
  	if request.format.html?
    	redirect_to root_path
    end
  end
end
