Rails.application.routes.draw do
  devise_for :users
  resource :profile, only: [:edit, :update]

  root to: "pages#home"

  resources :characters, only: [:index, :new, :create, :destroy]

  resources :events do
    resources :event_participations, only: [:create, :update, :destroy]
  end

  resources :wow_classes, only: [] do
    get :specializations, on: :member
  end

  # Routes pour le farm collaboratif
  get 'farm', to: 'farm#index'
  resources :consumable_selections, only: [:create, :update, :destroy]
  resources :farmer_assignments, only: [:create, :destroy]

  # Page dédiée Hauts Faits
  get 'achievements', to: 'achievements#index'
  post 'achievements/sync', to: 'achievements#sync', as: :sync_achievements

  # Ajoute cette ligne avec tes autres routes
get 'warcraft_logs_widget', to: 'pages#warcraft_logs_widget'
end
