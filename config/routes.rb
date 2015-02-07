Rails.application.routes.draw do
  root to: 'projects#index'

  resources :licenses, constraints: { :id => /.*/ }
  resources :languages

  get '/platforms', to: 'platforms#index', as: :platforms

  get '/users/github/:login', to: 'users#show', as: :user

  get '/search', to: 'search#index'

  # legacy
  get '/platforms/:id', to: 'legacy#platform'
  get '/users/:id', to: 'legacy#user'
  get '/projects/:id', to: 'legacy#project'
  get '/projects/:project_id/versions/:id', to: 'legacy#version', constraints: { :id => /.*/ }

  # project routes
  get '/:platform/:name/:number', to: 'projects#show', as: :version, constraints: { :number => /.*/, :name => /.*/ }
  get '/:platform/:name', to: 'projects#show', as: :project, constraints: { :name => /.*/ }
  get '/:id', to: 'platforms#show', as: :platform
end
