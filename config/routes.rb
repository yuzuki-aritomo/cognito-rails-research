Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  get 'home', to: 'home#index'
  get '/oauth2/callback', to: 'oauth2#callback'

  post 'signup', to: 'sessions#signup'
  post 'signup/confirm', to: 'sessions#confirm_user'
  post 'login', to: 'sessions#login'
end
