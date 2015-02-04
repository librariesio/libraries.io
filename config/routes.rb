Rails.application.routes.draw do
  root to: 'projects#index'
  resources :platforms
  resources :licenses
  get '/users/github/:login', to: 'users#show', as: :user
  resources :projects do
    resources :versions, :constraints => { :id => /.*/ }
  end
  get '/search', to: 'projects#search'
end
