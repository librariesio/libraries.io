Rails.application.routes.draw do
  require 'sidekiq/web'
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    username == ENV["SIDEKIQ_USERNAME"] && password == ENV["SIDEKIQ_PASSWORD"]
  end if Rails.env.production?
  mount Sidekiq::Web => '/sidekiq'

  mount PgHero::Engine, at: "pghero"

  get '/home', to: 'dashboard#home'

  namespace :api do
    post '/check', to: 'status#check'

    get '/', to: 'docs#index'
    get '/search', to: 'search#index'
    get '/bower-search', to: 'bower_search#index'
    get '/searchcode', to: 'projects#searchcode'

    get '/platforms', to: 'platforms#index'

    get '/subscriptions', to: 'subscriptions#index'
    get '/subscriptions/:platform/:name', to: 'subscriptions#show'
    post '/subscriptions/:platform/:name', to: 'subscriptions#create'
    put '/subscriptions/:platform/:name', to: 'subscriptions#update'
    delete '/subscriptions/:platform/:name', to: 'subscriptions#destroy'

    # legacy due to typo
    get '/subscription/:platform/:name', to: 'subscriptions#show'
    post '/subscription/:platform/:name', to: 'subscriptions#create'
    put '/subscription/:platform/:name', to: 'subscriptions#update'
    delete '/subscription/:platform/:name', to: 'subscriptions#destroy'

    scope constraints: {host_type: /(github|gitlab|bitbucket)/i}, defaults: { host_type: 'github' } do
      get '/:host_type/issues/help-wanted', to: 'issues#help_wanted'
      get '/:host_type/issues/first-pull-request', to: 'issues#first_pull_request'

      get '/:host_type/search', to: 'repositories#search'

      get '/:host_type/:login/repositories', to: 'repository_users#repositories'
      get '/:host_type/:login/projects', to: 'repository_users#projects'

      get '/:host_type/:owner/:name/dependencies', to: 'repositories#dependencies', constraints: { :name => /[^\/]+/ }
      get '/:host_type/:owner/:name/projects', to: 'repositories#projects', constraints: { :name => /[^\/]+/ }
      get '/:host_type/:owner/:name', to: 'repositories#show', constraints: { :name => /[^\/]+/ }

      get '/:host_type/:login', to: 'repository_users#show'
    end

    get '/:platform/:name/:version/tree', to: 'tree#show', constraints: { :platform => /[\w\-]+/, :name => /[\w\-\%]+/, :version => /[\w\.\-]+/ }, as: :version_tree
    get '/:platform/:name/:version/dependencies', to: 'projects#dependencies', constraints: { :platform => /[\w\-]+/, :name => /[\w\-\%]+/, :version => /[\w\.\-]+/ }
    get '/:platform/:name/dependent_repositories', to: 'projects#dependent_repositories', constraints: { :platform => /[\w\-]+/, :name => /[\w\.\-\%]+/ }
    get '/:platform/:name/dependents', to: 'projects#dependents', constraints: { :platform => /[\w\-]+/, :name => /[\w\.\-\%]+/ }
    get '/:platform/:name/tree', to: 'tree#show', constraints: { :platform => /[\w\-]+/, :name => /[\w\.\-\%]+/ }, as: :tree
    get '/:platform/:name', to: 'projects#show', constraints: { :platform => /[\w\-]+/, :name => /[\w\.\-\%]+/ }
  end

  namespace :admin do
    resources :projects do
      collection do
        get 'deprecated'
        get 'unmaintained'
      end
    end
    resources :project_suggestions
    resources :repositories do
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
    get '/stats/repositories', to: 'stats#repositories', as: :repositories_stats
    get '/graphs', to: 'stats#graphs', as: :graphs
    get '/', to: 'stats#overview', as: :overview
  end

  get '/trending', to: 'projects#trending', as: :trending_projects
  get '/explore', to: 'explore#index'
  get '/collections', to: 'collections#index', as: :collections
  get '/explore/:language-:keyword-libraries', to: 'collections#show', as: :collection

  get '/recommendations', to: 'recommendations#index', as: :recommendations

  get '/repositories', to: 'dashboard#index', as: :repositories
  get '/dashboard', to: redirect("/repositories")
  get '/muted', to: 'dashboard#muted', as: :muted
  post '/repositories/sync', to: 'dashboard#sync', as: :sync
  post '/watch/:repository_id', to: 'dashboard#watch', as: :watch
  post '/unwatch/:repository_id', to: 'dashboard#unwatch', as: :unwatch

  resource :account do
    member do
      get 'delete'
      put 'disable_emails'
    end
  end

  root to: 'projects#index'

  get '/404', to: 'errors#not_found'
  get '/422', to: 'errors#unprocessable'
  get '/500', to: 'errors#internal'

  resources :licenses, constraints: { :id => /.*/ }, :defaults => { :format => 'html' }
  resources :languages
  resources :keywords, constraints: { :id => /.*/ }, :defaults => { :format => 'html' }
  resources :subscriptions
  resources :repository_subscriptions
  get '/subscribe/:project_id', to: 'subscriptions#subscribe', as: :subscribe

  get '/stats', to: redirect('/admin/stats')

  #explore
  get '/explore/unlicensed-libraries', to: 'projects#unlicensed', as: :unlicensed
  get '/explore/unmaintained-libraries', to: 'projects#unmaintained', as: :unmaintained
  get '/explore/deprecated-libraries', to: 'projects#deprecated', as: :deprecated
  get '/explore/removed-libraries', to: 'projects#removed', as: :removed
  get '/explore/help-wanted', to: 'issues#help_wanted', as: :help_wanted
  get '/explore/first-pull-request', to: 'issues#first_pull_request', as: :first_pull_request
  get '/explore/issues', to: 'issues#index', as: :all_issues
  get '/unlicensed-libraries', to: redirect("/explore/unlicensed-libraries")
  get 'unmaintained-libraries', to: redirect("/explore/unmaintained-libraries")
  get 'deprecated-libraries', to: redirect("/explore/deprecated-libraries")
  get 'removed-libraries', to: redirect("/explore/removed-libraries")
  get '/help-wanted', to: redirect("/explore/help-wanted")
  get '/first-pull-request', to: redirect("/explore/first-pull-request")

  get '/platforms', to: 'platforms#index', as: :platforms

  scope constraints: {host_type: /(github|gitlab|bitbucket)/i}, defaults: { host_type: 'github' } do
    get '/:host_type/issues', to: 'issues#index', as: :issues
    get '/:host_type/issues/your-dependencies', to: 'issues#your_dependencies', as: :your_dependencies_issues

    post '/hooks/:host_type', to: 'hooks#github'

    get '/:host_type/languages', to: 'repositories#languages', as: :github_languages
    get '/:host_type/search', to: 'repositories#search', as: :github_search
    get '/:host_type/trending', to: 'repositories#hacker_news', as: :trending
    get '/:host_type/new', to: 'repositories#new', as: :new_repos
    get '/:host_type/organisations', to: 'repository_organisations#index', as: :repository_organisations
    get '/:host_type/timeline', to: 'repositories#timeline', as: :github_timeline
    get '/:host_type/:login/issues', to: 'repository_users#issues'
    get '/:host_type/:login/dependencies', to: 'repository_users#dependencies', as: :user_dependencies
    get '/:host_type/:login/dependency-issues', to: 'repository_users#dependency_issues'
    get '/:host_type/:login/repositories', to: 'repository_users#repositories', as: :user_repositories
    get '/:host_type/:login/contributions', to: 'repository_users#contributions', as: :user_contributions
    get '/:host_type/:login/projects', to: 'repository_users#projects', as: :user_projects
    get '/:host_type/:login/contributors', to: 'repository_users#contributors', as: :user_contributors
    get '/:host_type/:login', to: 'repository_users#show', as: :user

    get '/:host_type/:owner/:name', to: 'repositories#show', as: :repository, :defaults => { :format => 'html' }, constraints: { :name => /[\w\.\-\%]+/ }
    get '/:host_type/:owner/:name/contributors', to: 'repositories#contributors', as: :repository_contributors, format: false, constraints: { :name => /[^\/]+/ }
    post '/:host_type/:owner/:name/sync', to: 'repositories#sync', as: :sync_repository, format: false, constraints: { :name => /[^\/]+/ }
    get '/:host_type/:owner/:name/sourcerank', to: 'repositories#sourcerank', as: :repository_sourcerank, format: false, constraints: { :name => /[^\/]+/ }
    get '/:host_type/:owner/:name/forks', to: 'repositories#forks', as: :repository_forks, format: false, constraints: { :name => /[^\/]+/ }
    get '/:host_type/:owner/:name/tags', to: 'repositories#tags', as: :repository_tags, format: false, constraints: { :name => /[^\/]+/ }
    get '/:host_type/:owner/:name/dependency-issues', to: 'repositories#dependency_issues', format: false, constraints: { :name => /[^\/]+/ }
    get '/:host_type/:owner/:name/dependencies', to: 'repositories#dependencies', format: false, constraints: { :name => /[^\/]+/ }, as: :repository_dependencies
    get '/:host_type/:owner/:name/tree', to: 'repository_tree#show', as: :repository_tree, format: false, constraints: { :name => /[^\/]+/ }

    get '/:host_type/:owner/:name/web_hooks', to: 'web_hooks#index', as: :repository_web_hooks, format: false, constraints: { :name => /[^\/]+/ }
    get '/:host_type/:owner/:name/web_hooks/new', to: 'web_hooks#new', as: :new_repository_web_hook, format: false, constraints: { :name => /[^\/]+/ }
    delete '/:host_type/:owner/:name/web_hooks/:id', to: 'web_hooks#destroy', as: :repository_web_hook, format: false, constraints: { :name => /[^\/]+/ }
    patch '/:host_type/:owner/:name/web_hooks/:id', to: 'web_hooks#update', format: false, constraints: { :name => /[^\/]+/ }
    get '/:host_type/:owner/:name/web_hooks/:id/edit', to: 'web_hooks#edit', as: :edit_repository_web_hook, format: false, constraints: { :name => /[^\/]+/ }
    post '/:host_type/:owner/:name/web_hooks/:id/test', to: 'web_hooks#test', as: :test_repository_web_hook, format: false, constraints: { :name => /[^\/]+/ }
    post '/:host_type/:owner/:name/web_hooks', to: 'web_hooks#create', format: false, constraints: { :name => /[^\/]+/ }

    get '/:host_type', to: 'repositories#index', as: :hosts
  end

  #redirect after other issues routes created
  get '/issues', to: redirect('explore/issues')

  get '/repos/search', to: 'repositories#search', as: :repo_search
  get '/repos', to: 'repositories#index', as: :repos

  get '/search', to: 'search#index'

  get '/sitemap.xml.gz', to: redirect("https://#{ENV['FOG_DIRECTORY']}.s3.amazonaws.com/sitemaps/sitemap.xml.gz")

  get '/enable_private', to: 'sessions#enable_private', as: :enable_private
  get '/enable_public', to: 'sessions#enable_public', as: :enable_public
  get '/login',  to: 'sessions#new',     as: 'login'
  get '/logout', to: 'sessions#destroy', as: 'logout'

  match '/auth/:provider/callback', to: 'sessions#create', via: [:get, :post]
  post '/auth/failure',             to: 'sessions#failure'

  #experiments
  get '/experiments', to: 'pages#experiments', as: :experiments
  get '/experiments/bus-factor', to: 'projects#bus_factor', as: :bus_factor
  get '/experiments/unseen-infrastructure', to: 'projects#unseen_infrastructure', as: :unseen_infrastructure
  get '/experiments/digital-infrastructure', to: 'projects#digital_infrastructure', as: :digital_infrastructure
  get 'bus-factor', to: redirect("/experiments/bus-factor")
  get '/unseen-infrastructure', to: redirect("/experiments/unseen-infrastructure")
  get '/digital-infrastructure', to: redirect("/experiments/digital-infrastructure")

  #content
  get '/about', to: 'pages#about', as: :about
  get '/team', to: 'pages#team', as: :team
  get '/privacy', to: 'pages#privacy', as: :privacy
  get '/terms', to: 'pages#terms', as: :terms
  get '/compatibility', to: 'pages#compatibility', as: :compatibility
  get '/data', to: 'pages#data', as: :data
  get '/open-data', to: redirect("/data")

  post '/hooks/package', to: 'hooks#package'

  get '/:platform/:name/suggestions', to: 'project_suggestions#new', as: :project_suggestions, constraints: { :name => /.*/ }
  post '/:platform/:name/suggestions', to: 'project_suggestions#create', constraints: { :name => /.*/ }

  # project routes
  get '/:platform/:name/top_dependent_repos', to: 'projects#top_dependent_repos', as: :top_dependent_repos, constraints: { :name => /.*/ }, :defaults => { :format => 'html' }
  get '/:platform/:name/top_dependent_projects', to: 'projects#top_dependent_projects', as: :top_dependent_projects, constraints: { :name => /.*/ }, :defaults => { :format => 'html' }
  get '/:platform/:name/:number/dependencies', to: 'projects#dependencies', constraints: { :number => /.*/, :name => /.*/ }, as: :version_dependencies

  post '/:platform/:name/sync', to: 'projects#sync', constraints: { :name => /.*/ }, as: :sync_project
  get '/:platform/:name/unsubscribe', to: 'projects#unsubscribe', constraints: { :name => /.*/ }, as: :unsubscribe_project
  get '/:platform/:name/usage', to: 'project_usage#show', as: :project_usage, constraints: { :name => /.*/ }, :defaults => { :format => 'html' }
  post '/:platform/:name/mute', to: 'projects#mute', as: :mute_project, constraints: { :name => /.*/ }
  delete '/:platform/:name/unmute', to: 'projects#unmute', as: :unmute_project, constraints: { :name => /.*/ }
  get '/:platform/:name/tree', to: 'tree#show', constraints: { :name => /[\w\.\-\%]+/ }, as: :tree
  get '/:platform/:name/sourcerank', to: 'projects#sourcerank', as: :project_sourcerank, constraints: { :name => /.*/ }
  get '/:platform/:name/versions', to: 'projects#versions', as: :project_versions, constraints: { :name => /.*/ }
  get '/:platform/:name/tags', to: 'projects#tags', as: :project_tags, constraints: { :name => /.*/ }
  get '/:platform/:name/dependents', to: 'projects#dependents', as: :project_dependents, constraints: { :name => /.*/ }
  get '/:platform/:name/dependent_repositories', to: 'projects#dependent_repos', as: :legacy_project_dependent_repos, constraints: { :name => /.*/ }
  get '/:platform/:name/dependent-repositories', to: 'projects#dependent_repos', as: :project_dependent_repos, constraints: { :name => /.*/ }
  get '/:platform/:name/dependent-repositories/yours', to: 'projects#your_dependent_repos', as: :your_project_dependent_repos, constraints: { :name => /.*/ }
  get '/:platform/:name/:number.about', to: 'projects#about', as: :about_version, constraints: { :number => /.*/, :name => /.*/ }
  get '/:platform/:name/:number.ABOUT', to: 'projects#about', constraints: { :number => /.*/, :name => /.*/ }
  get '/:platform/:name/:number/tree', to: 'tree#show', constraints: { :number => /[\w\.\-\%]+/, :name => /[\w\.\-\%]+/ }, as: :version_tree
  get '/:platform/:name/:number', to: 'projects#show', as: :version, constraints: { :number => /.*/, :name => /.*/ }
  get '/:platform/:name.about', to: 'projects#about', as: :about_project, constraints: { :name => /.*/ }
  get '/:platform/:name.ABOUT', to: 'projects#about', constraints: { :name => /.*/ }
  get '/:platform/:name', to: 'projects#show', as: :project, constraints: { :name => /.*/ }, :defaults => { :format => 'html' }
  get '/:id', to: 'platforms#show', as: :platform
end
