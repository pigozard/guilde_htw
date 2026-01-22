Rails.application.routes.draw do
  get 'farm/index'
  devise_for :users
  root to: "pages#home"

  resources :characters, only: [:index, :new, :create, :destroy]

  resources :events do
    resources :event_participations, only: [:create, :update, :destroy]
  end

  resources :wow_classes, only: [] do
    get :specializations, on: :member
  end

  get 'farm', to: 'farm#index'
  resources :farm_contributions, only: [:create, :update, :destroy]
  resources :consumable_selections, only: [:create, :destroy]
end
