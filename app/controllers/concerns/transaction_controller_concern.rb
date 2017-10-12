module TransactionControllerConcern
  extend ActiveSupport::Concern

  included do
    helper_method :sort_column
    helper_method :sort_direction
  end

  def sort_column
		['tx_date','account','details','notes','credit', 'debit'].include?(params[:sort]) ? params[:sort] : "tx_date"
	end

	def sort_direction
		%w[asc desc].include?(params[:direction]) ?  params[:direction] : "desc"
	end
end
