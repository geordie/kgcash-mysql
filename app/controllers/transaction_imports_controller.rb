class TransactionImportsController < ApplicationController
  def new
    @user = current_user
    @accounts = @user.account_selector
    @transaction_import = TransactionImport.new
  end

  def create
    @user = current_user
    @accounts = @user.account_selector
    @transaction_import = TransactionImport.new(params[:transaction_import])
    if @transaction_import.save
      redirect_to transactions_path, notice: "Transactions imported successfully."
    else
      render :new
    end
  end
end
