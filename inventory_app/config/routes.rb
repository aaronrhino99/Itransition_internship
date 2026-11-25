Rails.application.routes.draw do
  # The main page of the app: http://localhost:3000/
  root "home#index"

  # Health check used by Render to see if the app is up.
  get "up" => "rails/health#show", as: :rails_health_check
end
