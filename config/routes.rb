Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  resources :characters, only: [:index, :new, :create, :destroy]

  resources :events do
    resources :event_participations, only: [:create, :update, :destroy]
  end

  resources :wow_classes, only: [] do
    get :specializations, on: :member
  end
end
