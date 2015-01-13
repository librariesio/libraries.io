Rails.application.routes.draw do
  root :to => 'projects#index'
  resources :projects
  get '/search', :to => 'projects#search'
end
