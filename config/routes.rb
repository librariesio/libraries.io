Rails.application.routes.draw do
  root to: 'projects#index'

  resources :licenses
  resources :languages

  get '/platforms', to: 'platforms#index', as: :platforms

  get '/users/github/:login', to: 'users#show', as: :user

  get '/search', to: 'projects#search'

  # legacy
  get '/platforms/:id', to: 'platforms#legacy'
  get '/users/:id', to: 'users#legacy'
  get '/projects/:id', to: 'projects#legacy'
  get '/projects/:project_id/versions/:id', to: 'versions#legacy', constraints: { :id => /.*/ }

  # project routes
  get '/:platform/:name/:number', to: 'versions#show', as: :version, constraints: { :number => /.*/, :name => /.*/ }
  get '/:platform/:name', to: 'projects#show', as: :project, constraints: { :name => /.*/ }
  get '/:id', to: 'platforms#show', as: :platform
end
