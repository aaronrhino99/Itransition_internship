Rails.application.routes.draw do
  devise_for :users
  root "users#index"
  patch "users/bulk", to: "users#bulk", as: :bulk_users

  get "up" => "rails/health#show", as: :rails_health_check
end
