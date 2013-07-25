class TransactionImportsController < ApplicationController
  def new
    @transaction_import = TransactionImport.new
  end

  def create
    @transaction_import = TransactionImport.new(params[:transaction_import])
    if @transaction_import.save
      redirect_to transactions_path, notice: "Transactions imported successfully."
    else
      render :new
    end
  end
end
