Rails.application.routes.draw do
  require 'sidekiq/web'
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    username == ENV["SIDEKIQ_USERNAME"] && password == ENV["SIDEKIQ_PASSWORD"]
  end if Rails.env.production?
  mount Sidekiq::Web => '/sidekiq'

  namespace :api do
    get '/search', to: 'search#index'
    get '/searchcode', to: 'projects#searchcode'
    get '/github/:owner/:name/star', to: 'github_repositories#star', constraints: { :name => /.*/ }
    get '/github/:owner/:name', to: 'github_repositories#show', constraints: { :name => /.*/ }
    post '/:platform/projects', to: 'projects#list'
    get '/:platform/:name', to: 'projects#show', constraints: { :name => /.*/ }
  end

  namespace :admin do
    resources :projects
    resources :github_repositories do
      collection do
        get 'mit'
      end
    end
    resources :users do
      member do
        post 'sync'
      end
    end
    get '/stats', to: 'stats#index', as: :stats
    get '/stats/github', to: 'stats#github', as: :github_stats
  end

  get '/recommendations', to: 'recommendations#index', as: :recommendations

  post '/hooks/github', to: 'hooks#github'

  get '/repositories', to: 'dashboard#index', as: :repositories
  get '/dashboard', to: redirect("/repositories")
  post '/repositories/sync', to: 'dashboard#sync', as: :sync
  post '/watch/:github_repository_id', to: 'dashboard#watch', as: :watch
  post '/unwatch/:github_repository_id', to: 'dashboard#unwatch', as: :unwatch

  resource :account do
    member do
      get 'delete'
    end
  end

  root to: 'projects#index'

  get '/404', to: 'errors#not_found'
  get '/422', to: 'errors#unprocessable'
  get '/500', to: 'errors#internal'

  resources :licenses, constraints: { :id => /.*/ }
  resources :languages
  resources :keywords, constraints: { :id => /.*/ }
  resources :subscriptions
  get '/subscribe/:project_id', to: 'subscriptions#subscribe', as: :subscribe

  get '/stats', to: redirect('/admin/stats')

  get 'bus-factor', to: 'projects#bus_factor', as: :bus_factor
  get '/unlicensed-libraries', to: 'projects#unlicensed', as: :unlicensed

  get '/platforms', to: 'platforms#index', as: :platforms

  get '/github/trending', to: 'github_repositories#hacker_news', as: :trending
  get 'hacker_news' => redirect('/github/trending')
  get '/github/new', to: 'github_repositories#new', as: :new_repos

  get '/github/organisations', to: 'github_organisations#index', as: :github_organisations
  get '/github/timeline', to: 'github_repositories#timeline', as: :github_timeline

  get '/github/:login/repositories', to: 'users#repositories', as: :user_repositories
  get '/github/:login/contributions', to: 'users#contributions', as: :user_contributions
  get '/github/:login', to: 'users#show', as: :user

  get '/mozilla', to: 'github_organisations#mozilla', as: :mozilla

  get '/search', to: 'search#index'

  get '/sitemap.xml.gz', to: redirect("https://#{ENV['FOG_DIRECTORY']}.s3.amazonaws.com/sitemaps/sitemap.xml.gz")

  get '/login',  to: 'sessions#new',     as: 'login'
  get '/logout', to: 'sessions#destroy', as: 'logout'

  match '/auth/:provider/callback', to: 'sessions#create', via: [:get, :post]
  post '/auth/failure',             to: 'sessions#failure'

  get '/github/:owner/:name', to: 'github_repositories#show', as: :github_repository, format: false, constraints: { :name => /[^\/]+/ }
  get '/github/:owner/:name/contributors', to: 'github_repositories#contributors', as: :github_repository_contributors, format: false, constraints: { :name => /[^\/]+/ }
  get '/github/:owner/:name/forks', to: 'github_repositories#forks', as: :github_repository_forks, format: false, constraints: { :name => /[^\/]+/ }

  get '/github', to: 'github_repositories#index', as: :github

  get '/about', to: 'pages#about', as: :about

  # legacy
  get '/platforms/:id', to: 'legacy#platform'
  get '/users/:id', to: 'legacy#user'
  get '/users/github/:login', to: 'legacy#github_user'
  get '/projects/:id', to: 'legacy#project'
  get '/projects/:project_id/versions/:id', to: 'legacy#version', constraints: { :id => /.*/ }

  if Rails.env.development?
    get '/rails/mailers'         => "rails/mailers#index"
    get '/rails/mailers/*path'   => "rails/mailers#preview"
  end

  # project routes
  post '/:platform/:name/mute', to: 'projects#mute', as: :mute_project, constraints: { :name => /.*/ }
  delete '/:platform/:name/unmute', to: 'projects#unmute', as: :unmute_project, constraints: { :name => /.*/ }
  get '/:platform/:name/versions', to: 'projects#versions', as: :project_versions, constraints: { :name => /.*/ }
  get '/:platform/:name/tags', to: 'projects#tags', as: :project_tags, constraints: { :name => /.*/ }
  get '/:platform/:name/dependents', to: 'projects#dependents', as: :project_dependents, constraints: { :name => /.*/ }
  get '/:platform/:name/dependent_repositories', to: 'projects#dependent_repos', as: :legacy_project_dependent_repos, constraints: { :name => /.*/ }
  get '/:platform/:name/dependent-repositories', to: 'projects#dependent_repos', as: :project_dependent_repos, constraints: { :name => /.*/ }
  get '/:platform/:name/dependent-repositories/yours', to: 'projects#your_dependent_repos', as: :your_project_dependent_repos, constraints: { :name => /.*/ }
  get '/:platform/:name/:number', to: 'projects#show', as: :version, constraints: { :number => /.*/, :name => /.*/ }
  get '/:platform/:name', to: 'projects#show', as: :project, constraints: { :name => /.*/ }
  get '/:id', to: 'platforms#show', as: :platform
end
