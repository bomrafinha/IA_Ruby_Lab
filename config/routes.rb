Rails.application.routes.draw do
  root "home#index"

  get "up" => "rails/health#show", as: :rails_health_check
  get "experimentos/:slug", to: "experiments#show", as: :experiment
  post "experimentos/:slug/run", to: "experiments#run", as: :run_experiment
end
