Rails.application.routes.draw do
  root to: 'projects#index'
  resources :platforms
  resources :users
  resources :projects do
    resources :versions, :constraints => { :id => /.*/ }
  end
  get '/search', to: 'projects#search'
end
