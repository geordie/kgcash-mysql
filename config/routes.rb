Kgcash::Application.routes.draw do

root :to => 'welcome#index', :constraints => UserRequiredConstraint.new
root :to => 'static_pages#home', :constraints => NoUserRequiredConstraint.new, as: nil

resources :user_sessions

resources :users

resources :transactions do
  get 'new_attachment'
  patch 'update_attachment'
  delete 'delete_attachment'
  collection do
    get 'uncategorized'
  end
end

resources :documents

resources :transaction_imports

resources :expenses do
  collection do
    post 'split_commit'
  end
  collection do
    get 'split'
  end
end

resources :incomes

resources :payments

resources :asset_transfers

resources :reports do
  collection do
    get 'income', to: 'reports#income'
    get 'cashflow', to: 'reports#cashflow'
    get 'alltime', to: 'reports#alltime'
    get 'alltime_expenses', to: 'reports#alltime_expenses'
    get 'alltime_revenue', to: 'reports#alltime_revenue'
  end
end

resources :accounts do
  collection do
    get 'spending'
  end
end

resources :categories


match 'login' => 'user_sessions#new', :as => :login, via: [:get, :post]
match 'logout' => 'user_sessions#destroy', :as => :logout, via: [:get, :post]

end
