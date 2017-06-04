class StaticPagesController < ApplicationController
  skip_before_filter :require_login
  layout :false

  def home
    respond_to do |format|
			format.html
		end
  end

end
