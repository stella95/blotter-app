Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  devise_for :users, controllers: { sessions: "users/sessions" }

  root "dashboard#index"
  get "dashboard", to: "dashboard#index"

  resources :portfolios do
    member do
      patch :archive
    end
  end

  resources :entries, only: %i[index new create]
  resources :categories, only: %i[index new create destroy]

  # path: avoids colliding with Rails' own asset pipeline prefix (/assets),
  # which is served by middleware ahead of the router. Route helper names
  # and the controller are unaffected, only the URL segment changes.
  resources :assets, path: "instruments", only: %i[index new create] do
    resources :prices, only: :create, controller: "asset_prices"
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
