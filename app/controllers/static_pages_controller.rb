class StaticPagesController < ApplicationController
  skip_before_action :require_login
  layout :false

  def home
    respond_to do |format|
			format.html
		end
  end

end
