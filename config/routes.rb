Rails.application.routes.draw do
  get 'characters/index'
  get 'characters/new'
  get 'characters/create'
  devise_for :users
  root to: "characters#index"

  resources :characters, only: [:index, :new, :create, :destroy]
end
