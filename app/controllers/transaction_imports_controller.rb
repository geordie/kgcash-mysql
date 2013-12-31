class TransactionImportsController < ApplicationController
  def new
    @user = current_user
    @accounts = @user.account_selector
    @transaction_import = TransactionImport.new

    @format = TransactionImportFormatVancity.new
  end

  def create
    @user = current_user
    @accounts = @user.account_selector
    @transaction_import = TransactionImport.new(params[:transaction_import])
    @transaction_import_format = TransactionImportFormatVancity.new
    if @transaction_import.save @transaction_import_format
      redirect_to transactions_path, notice: "Transactions imported successfully."
    else
      render :new
    end
  end
end
