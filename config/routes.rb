Rails.application.routes.draw do
  mount Payola::Engine => '/payola', as: :payola
  require 'sidekiq/web'
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    username == ENV["SIDEKIQ_USERNAME"] && password == ENV["SIDEKIQ_PASSWORD"]
  end if Rails.env.production?
  mount Sidekiq::Web => '/sidekiq'

  get '/home', to: 'dashboard#home'

  namespace :api do
    post '/check', to: 'status#check'

    get '/', to: 'docs#index'
    get '/search', to: 'search#index'
    get '/bower-search', to: 'bower_search#index'
    get '/searchcode', to: 'projects#searchcode'

    get '/subscriptions', to: 'subscriptions#index'
    get '/subscription/:platform/:name', to: 'subscriptions#show'
    post '/subscription/:platform/:name', to: 'subscriptions#create'
    put '/subscription/:platform/:name', to: 'subscriptions#update'
    delete '/subscription/:platform/:name', to: 'subscriptions#destroy'

    get '/github/issues/help-wanted', to: 'github_issues#help_wanted'
    get '/github/issues/first-pull-request', to: 'github_issues#first_pull_request'

    get '/github/search', to: 'github_repositories#search'

    get '/github/:login/repositories', to: 'github_users#repositories'
    get '/github/:login/projects', to: 'github_users#projects'

    get '/github/:owner/:name/dependencies', to: 'github_repositories#dependencies', constraints: { :name => /[^\/]+/ }
    get '/github/:owner/:name/projects', to: 'github_repositories#projects', constraints: { :name => /[^\/]+/ }
    get '/github/:owner/:name', to: 'github_repositories#show', constraints: { :name => /[^\/]+/ }

    get '/github/:login', to: 'github_users#show'

    get '/:platform/:name/:version/dependencies', to: 'projects#dependencies', constraints: { :platform => /[\w\-\_]+/, :name => /[\w\-\_\%]+/, :version => /[\w\.\-\_\.]+/ }
    get '/:platform/:name/dependent_repositories', to: 'projects#dependent_repositories', constraints: { :platform => /[\w\-\_]+/, :name => /[\w\.\-\_\%]+/ }
    get '/:platform/:name/dependents', to: 'projects#dependents', constraints: { :platform => /[\w\-\_]+/, :name => /[\w\.\-\_\%]+/ }
    get '/:platform/:name', to: 'projects#show', constraints: { :platform => /[\w\-\_]+/, :name => /[\w\.\-\_\%]+/ }
  end

  namespace :admin do
    resources :projects do
      collection do
        get 'deprecated'
        get 'unmaintained'
      end
    end
    resources :project_suggestions
    resources :github_repositories do
      member do
        put 'deprecate'
        put 'unmaintain'
      end
      collection do
        get 'deprecated'
        get 'unmaintained'
      end
    end
    get '/stats', to: 'stats#index', as: :stats
    get '/stats/github', to: 'stats#github', as: :github_stats
  end

  get '/github/issues', to: 'github_issues#index', as: :issues

  get '/pricing', to: 'account_subscriptions#plans', as: :pricing
  resources :account_subscriptions

  get '/recommendations', to: 'recommendations#index', as: :recommendations

  post '/hooks/github', to: 'hooks#github'

  get '/repositories', to: 'dashboard#index', as: :repositories
  get '/dashboard', to: redirect("/repositories")
  get '/muted', to: 'dashboard#muted', as: :muted
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
  resources :repository_subscriptions
  get '/subscribe/:project_id', to: 'subscriptions#subscribe', as: :subscribe

  get '/stats', to: redirect('/admin/stats')

  get 'bus-factor', to: 'projects#bus_factor', as: :bus_factor
  get '/unlicensed-libraries', to: 'projects#unlicensed', as: :unlicensed
  get 'unmaintained-libraries', to: 'projects#unmaintained', as: :unmaintained
  get 'deprecated-libraries', to: 'projects#deprecated', as: :deprecated
  get 'removed-libraries', to: 'projects#removed', as: :removed

  get '/help-wanted', to: 'github_issues#help_wanted', as: :help_wanted
  get '/first-pull-request', to: 'github_issues#first_pull_request', as: :first_pull_request

  get '/platforms', to: 'platforms#index', as: :platforms

  get '/github/search', to: 'github_repositories#search', as: :github_search
  get '/github/trending', to: 'github_repositories#hacker_news', as: :trending
  get 'hacker_news' => redirect('/github/trending')
  get '/github/new', to: 'github_repositories#new', as: :new_repos

  get '/github/organisations', to: 'github_organisations#index', as: :github_organisations
  get '/github/timeline', to: 'github_repositories#timeline', as: :github_timeline

  get '/github/:login/repositories', to: 'users#repositories', as: :user_repositories
  get '/github/:login/contributions', to: 'users#contributions', as: :user_contributions
  get '/github/:login/projects', to: 'users#projects', as: :user_projects
  get '/github/:login', to: 'users#show', as: :user

  get '/search', to: 'search#index'

  get '/sitemap.xml.gz', to: redirect("https://#{ENV['FOG_DIRECTORY']}.s3.amazonaws.com/sitemaps/sitemap.xml.gz")

  get '/enable_private', to: 'sessions#enable_private', as: :enable_private
  get '/enable_public', to: 'sessions#enable_public', as: :enable_public
  get '/login',  to: 'sessions#new',     as: 'login'
  get '/logout', to: 'sessions#destroy', as: 'logout'

  match '/auth/:provider/callback', to: 'sessions#create', via: [:get, :post]
  post '/auth/failure',             to: 'sessions#failure'

  get '/github/:owner/:name', to: 'github_repositories#show', as: :github_repository, format: false, constraints: { :name => /[^\/]+/ }
  get '/github/:owner/:name/contributors', to: 'github_repositories#contributors', as: :github_repository_contributors, format: false, constraints: { :name => /[^\/]+/ }
  get '/github/:owner/:name/forks', to: 'github_repositories#forks', as: :github_repository_forks, format: false, constraints: { :name => /[^\/]+/ }

  get '/github/:owner/:name/web_hooks', to: 'web_hooks#index', as: :github_repository_web_hooks, format: false, constraints: { :name => /[^\/]+/ }
  get '/github/:owner/:name/web_hooks/new', to: 'web_hooks#new', as: :new_github_repository_web_hook, format: false, constraints: { :name => /[^\/]+/ }
  delete '/github/:owner/:name/web_hooks/:id', to: 'web_hooks#destroy', as: :github_repository_web_hook, format: false, constraints: { :name => /[^\/]+/ }
  patch '/github/:owner/:name/web_hooks/:id', to: 'web_hooks#update', format: false, constraints: { :name => /[^\/]+/ }
  get '/github/:owner/:name/web_hooks/:id/edit', to: 'web_hooks#edit', as: :edit_github_repository_web_hook, format: false, constraints: { :name => /[^\/]+/ }
  post '/github/:owner/:name/web_hooks/:id/test', to: 'web_hooks#test', as: :test_github_repository_web_hook, format: false, constraints: { :name => /[^\/]+/ }
  post '/github/:owner/:name/web_hooks', to: 'web_hooks#create', format: false, constraints: { :name => /[^\/]+/ }

  get '/github', to: 'github_repositories#index', as: :github

  get '/about', to: 'pages#about', as: :about

  if Rails.env.development?
    get '/rails/mailers'         => "rails/mailers#index"
    get '/rails/mailers/*path'   => "rails/mailers#preview"
  end

  get '/:platform/:name/suggestions', to: 'project_suggestions#new', as: :project_suggestions, constraints: { :name => /.*/ }
  post '/:platform/:name/suggestions', to: 'project_suggestions#create', constraints: { :name => /.*/ }

  # project routes
  post '/:platform/:name/mute', to: 'projects#mute', as: :mute_project, constraints: { :name => /.*/ }
  delete '/:platform/:name/unmute', to: 'projects#unmute', as: :unmute_project, constraints: { :name => /.*/ }
  get '/:platform/:name/sourcerank', to: 'projects#sourcerank', as: :project_sourcerank, constraints: { :name => /.*/ }
  get '/:platform/:name/versions', to: 'projects#versions', as: :project_versions, constraints: { :name => /.*/ }
  get '/:platform/:name/tags', to: 'projects#tags', as: :project_tags, constraints: { :name => /.*/ }
  get '/:platform/:name/dependents', to: 'projects#dependents', as: :project_dependents, constraints: { :name => /.*/ }
  get '/:platform/:name/dependent_repositories', to: 'projects#dependent_repos', as: :legacy_project_dependent_repos, constraints: { :name => /.*/ }
  get '/:platform/:name/dependent-repositories', to: 'projects#dependent_repos', as: :project_dependent_repos, constraints: { :name => /.*/ }
  get '/:platform/:name/dependent-repositories/yours', to: 'projects#your_dependent_repos', as: :your_project_dependent_repos, constraints: { :name => /.*/ }
  get '/:platform/:name/:number.about', to: 'projects#about', as: :about_version, constraints: { :number => /.*/, :name => /.*/ }
  get '/:platform/:name/:number.ABOUT', to: 'projects#about', constraints: { :number => /.*/, :name => /.*/ }
  get '/:platform/:name/:number', to: 'projects#show', as: :version, constraints: { :number => /.*/, :name => /.*/ }
  get '/:platform/:name.about', to: 'projects#about', as: :about_project, constraints: { :name => /.*/ }
  get '/:platform/:name.ABOUT', to: 'projects#about', constraints: { :name => /.*/ }
  get '/:platform/:name', to: 'projects#show', as: :project, constraints: { :name => /.*/ }
  get '/:id', to: 'platforms#show', as: :platform
end
