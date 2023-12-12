# frozen_string_literal: true

PLATFORM_CONSTRAINT = /[\w-]+/.freeze
PROJECT_CONSTRAINT = /[^\/]+/.freeze
VERSION_CONSTRAINT = /[\w.-]+/.freeze

class IsAdminConstraint
  def matches?(request)
    User.find_by_id(request.session[:user_id])&.admin? || false
  end
end

Rails.application.routes.draw do
  require "sidekiq/web"
  require "sidekiq_unique_jobs/web"
  mount Sidekiq::Web => "/sidekiq", constraints: Rails.env.production? ? IsAdminConstraint.new : nil
  mount PgHero::Engine, at: "pghero", constraints: Rails.env.production? ? IsAdminConstraint.new : nil

  get "/healthcheck", to: "healthcheck#index", as: :healthcheck
  get "/home", to: "dashboard#home"

  namespace :api, defaults: { format: :json } do
    post "/check", to: "status#check"

    get "/", to: "docs#index", defaults: { format: :html }
    get "/search", to: "search#index"

    get "/platforms", to: "platforms#index"

    get "/versions", to: "versions#index"

    get "/subscriptions", to: "subscriptions#index"
    get "/subscriptions/:platform/:name", to: "subscriptions#show"
    post "/subscriptions/:platform/:name", to: "subscriptions#create"
    put "/subscriptions/:platform/:name", to: "subscriptions#update"
    delete "/subscriptions/:platform/:name", to: "subscriptions#destroy"

    # legacy due to typo
    get "/subscription/:platform/:name", to: "subscriptions#show"
    post "/subscription/:platform/:name", to: "subscriptions#create"
    put "/subscription/:platform/:name", to: "subscriptions#update"
    delete "/subscription/:platform/:name", to: "subscriptions#destroy"

    post "/projects/dependencies", to: "projects#dependencies_bulk"
    get "/projects/updated", to: "projects#updated"

    scope constraints: { host_type: /(github|gitlab|bitbucket)/i }, defaults: { host_type: "github" } do
      get "/:host_type/:login/dependencies", to: "repository_users#dependencies"
      get "/:host_type/:login/project-contributions", to: "repository_users#project_contributions"
      get "/:host_type/:login/repository-contributions", to: "repository_users#repository_contributions"
      get "/:host_type/:login/repositories", to: "repository_users#repositories"
      get "/:host_type/:login/projects", to: "repository_users#projects"

      get "/:host_type/:owner/:name/dependencies", to: "repositories#dependencies", constraints: { name: /[^\/]+/ }
      get "/:host_type/:owner/:name/projects", to: "repositories#projects", constraints: { name: /[^\/]+/ }
      get "/:host_type/:owner/:name", to: "repositories#show", constraints: { name: /[^\/]+/ }

      get "/:host_type/:login", to: "repository_users#show"
    end

    put "/maintenance/stats/enqueue/:platform/:name", as: :maintenance_stat_enqueue, to: "maintenance_stats#enqueue", constraints: { platform: PLATFORM_CONSTRAINT, name: PROJECT_CONSTRAINT }
    post "/maintenance/stats/begin/bulk", to: "maintenance_stats#begin_watching_bulk"
    get "/maintenance/stats/begin/:platform/:name", to: "maintenance_stats#begin_watching", constraints: { platform: PLATFORM_CONSTRAINT, name: PROJECT_CONSTRAINT }

    get "/:platform/:name/usage", to: "project_usage#show", as: :project_usage, constraints: { platform: PLATFORM_CONSTRAINT, name: PROJECT_CONSTRAINT }
    get "/:platform/:name/sourcerank", to: "projects#sourcerank", constraints: { platform: PLATFORM_CONSTRAINT, name: PROJECT_CONSTRAINT }
    get "/:platform/:name/contributors", to: "projects#contributors", constraints: { platform: PLATFORM_CONSTRAINT, name: PROJECT_CONSTRAINT }
    get "/:platform/:name/:number/tree", to: "tree#show", constraints: { platform: /[\w-]+/, name: PROJECT_CONSTRAINT, number: VERSION_CONSTRAINT }, as: :version_tree
    get "/:platform/:name/:number/dependencies", to: "projects#dependencies", constraints: { platform: PLATFORM_CONSTRAINT, name: PROJECT_CONSTRAINT, number: VERSION_CONSTRAINT }
    get "/:platform/:name/dependent_repositories", to: "projects#dependent_repositories", constraints: { platform: PLATFORM_CONSTRAINT, name: PROJECT_CONSTRAINT }
    get "/:platform/:name/dependents", to: "projects#dependents", constraints: { platform: PLATFORM_CONSTRAINT, name: PROJECT_CONSTRAINT }
    get "/:platform/:name/tree", to: "tree#show", constraints: { platform: PLATFORM_CONSTRAINT, name: PROJECT_CONSTRAINT }, as: :tree
    get "/:platform/:name/sync", to: "projects#sync", constraints: { platform: PLATFORM_CONSTRAINT, name: PROJECT_CONSTRAINT }, as: :sync
    get "/:platform/:name", to: "projects#show", constraints: { platform: PLATFORM_CONSTRAINT, name: PROJECT_CONSTRAINT }
  end

  namespace :admin do
    resources :projects do
      collection do
        get "deprecated"
        get "unmaintained"
      end
    end
    resources :project_suggestions
    resources :repositories do
      member do
        put "deprecate"
        put "unmaintain"
      end
    end

    get "/stats", to: "stats#index", as: :stats
    get "/stats/api", to: "stats#api", as: :api_stats
    get "/stats/repositories", to: "stats#repositories", as: :repositories_stats
    get "/:host_type/:login/dependencies", to: "repository_organisations#dependencies", as: :organisation_dependencies
    delete "/:host_type/:login", to: "repository_organisations#destroy"
    patch "/:host_type/:login", to: "repository_organisations#update"
    post "/:host_type/:login/hide", to: "repository_organisations#hide", as: :hide_owner
    get "/:host_type/:login/edit", to: "repository_organisations#edit", as: :edit_owner
    get "/:host_type/:login", to: "repository_organisations#show", as: :organisation
    get "/", to: "stats#overview", as: :overview
  end

  get "/trending", to: "projects#trending", as: :trending_projects
  get "/explore", to: "explore#index"
  get "/explore/:language-:keyword-libraries", to: "collections#show", as: :collection

  get "/recommendations", to: "recommendations#index", as: :recommendations

  get "/repositories", to: "dashboard#index", as: :repositories
  get "/dashboard", to: redirect("/repositories")
  get "/muted", to: "dashboard#muted", as: :muted
  post "/repositories/sync", to: "dashboard#sync", as: :sync
  post "/watch/:repository_id", to: "dashboard#watch", as: :watch
  post "/unwatch/:repository_id", to: "dashboard#unwatch", as: :unwatch

  resource :account, except: %i[edit new create] do
    member do
      get "delete"
      put "disable_emails"
      put "optin"
    end
  end

  root to: "projects#index"

  match "/404", to: "errors#not_found", via: :all
  match "/406", to: "errors#not_acceptable", via: :all
  match "/422", to: "errors#unprocessable", via: :all
  match "/500", to: "errors#internal", via: :all

  resources :licenses, constraints: { id: /.*/ }, defaults: { format: "html" }
  resources :languages
  resources :subscriptions
  resources :repository_subscriptions
  get "/subscribe/:project_id", to: "subscriptions#subscribe", as: :subscribe

  get "/stats", to: redirect("/admin/stats")

  get "/platforms", to: "platforms#index", as: :platforms

  scope constraints: { host_type: /(github|gitlab|bitbucket)/i }, defaults: { host_type: "github" } do
    post "/hooks/:host_type", to: "hooks#github"

    get "/:host_type/organisations", to: "repository_organisations#index", as: :repository_organisations
    get "/:host_type/:login/dependencies", to: "repository_users#dependencies", as: :user_dependencies
    get "/:host_type/:login/repositories", to: "repository_users#repositories", as: :user_repositories
    get "/:host_type/:login/contributions", to: "repository_users#contributions", as: :user_contributions
    get "/:host_type/:login/projects", to: "repository_users#projects", as: :user_projects
    get "/:host_type/:login/contributors", to: "repository_users#contributors", as: :user_contributors
    post "/:host_type/:login/sync", to: "repository_users#sync", as: :sync_user
    get "/:host_type/:login", to: "repository_users#show", as: :user

    get "/:host_type/:owner/:name", to: "repositories#show", as: :repository, defaults: { format: "html" }, constraints: { name: /[\w.\-%]+/ }
    get "/:host_type/:owner/:name/contributors", to: "repositories#contributors", as: :repository_contributors, format: false, constraints: { name: /[^\/]+/ }
    post "/:host_type/:owner/:name/sync", to: "repositories#sync", as: :sync_repository, format: false, constraints: { name: /[^\/]+/ }
    get "/:host_type/:owner/:name/sourcerank", to: "repositories#sourcerank", as: :repository_sourcerank, format: false, constraints: { name: /[^\/]+/ }
    get "/:host_type/:owner/:name/forks", to: "repositories#forks", as: :repository_forks, format: false, constraints: { name: /[^\/]+/ }
    get "/:host_type/:owner/:name/tags", to: "repositories#tags", as: :repository_tags, format: false, constraints: { name: /[^\/]+/ }
    get "/:host_type/:owner/:name/dependencies", to: "repositories#dependencies", format: false, constraints: { name: /[^\/]+/ }, as: :repository_dependencies
    get "/:host_type/:owner/:name/tree", to: "repository_tree#show", as: :repository_tree, format: false, constraints: { name: /[^\/]+/ }

    get "/:host_type/:owner/:name/web_hooks", to: "web_hooks#index", as: :repository_web_hooks, format: false, constraints: { name: /[^\/]+/ }
    get "/:host_type/:owner/:name/web_hooks/new", to: "web_hooks#new", as: :new_repository_web_hook, format: false, constraints: { name: /[^\/]+/ }
    delete "/:host_type/:owner/:name/web_hooks/:id", to: "web_hooks#destroy", as: :repository_web_hook, format: false, constraints: { name: /[^\/]+/ }
    patch "/:host_type/:owner/:name/web_hooks/:id", to: "web_hooks#update", format: false, constraints: { name: /[^\/]+/ }
    get "/:host_type/:owner/:name/web_hooks/:id/edit", to: "web_hooks#edit", as: :edit_repository_web_hook, format: false, constraints: { name: /[^\/]+/ }
    post "/:host_type/:owner/:name/web_hooks/:id/test", to: "web_hooks#test", as: :test_repository_web_hook, format: false, constraints: { name: /[^\/]+/ }
    post "/:host_type/:owner/:name/web_hooks", to: "web_hooks#create", format: false, constraints: { name: /[^\/]+/ }

    get "/:host_type", to: redirect("/")
  end

  get "/repos", to: redirect("/")

  get "/search", to: "search#index"

  get "/sitemap.xml.gz", to: redirect("/sitemaps/sitemap.xml.gz")

  get "/enable_private", to: "sessions#enable_private", as: :enable_private
  get "/enable_public", to: "sessions#enable_public", as: :enable_public
  get "/login",  to: "sessions#new",     as: "login"
  get "/logout", to: "sessions#destroy", as: "logout"

  match "/auth/:provider/callback", to: "sessions#create", via: %i[get post]
  post "/auth/failure",             to: "sessions#failure"

  # experiments
  get "/experiments", to: redirect("/")
  get "/experiments/*", to: redirect("/")

  # content
  get "/about", to: "pages#about", as: :about
  get "/team", to: "pages#team", as: :team
  get "/privacy", to: "pages#privacy", as: :privacy
  get "/terms", to: "pages#terms", as: :terms
  get "/compatibility", to: "pages#compatibility", as: :compatibility
  get "/data", to: redirect("/")
  get "/open-data", to: redirect("/")

  post "/hooks/package", to: "hooks#package"

  get "/:platform/:name/suggestions", to: "project_suggestions#new", as: :project_suggestions, constraints: { name: /.*/ }
  post "/:platform/:name/suggestions", to: "project_suggestions#create", constraints: { name: /.*/ }

  # project routes
  get "/:platform/:name/top_dependent_repos", to: "projects#top_dependent_repos", as: :top_dependent_repos, constraints: { name: /.*/ }, defaults: { format: "html" }
  get "/:platform/:name/top_dependent_projects", to: "projects#top_dependent_projects", as: :top_dependent_projects, constraints: { name: /.*/ }, defaults: { format: "html" }
  get "/:platform/:name/:number/dependencies", to: "projects#dependencies", constraints: { number: /.*/, name: /.*/ }, as: :version_dependencies

  post "/:platform/:name/sync", to: "projects#sync", constraints: { name: /.*/ }, as: :sync_project
  post "/:platform/:name/refresh-stats", to: "projects#refresh_stats", constraints: { name: /.*/ }, as: :project_refresh_stats
  get "/:platform/:name/unsubscribe", to: "projects#unsubscribe", constraints: { name: /.*/ }, as: :unsubscribe_project
  get "/:platform/:name/usage", to: "project_usage#show", as: :project_usage, constraints: { name: /.*/ }, defaults: { format: "html" }
  post "/:platform/:name/mute", to: "projects#mute", as: :mute_project, constraints: { name: /.*/ }
  delete "/:platform/:name/unmute", to: "projects#unmute", as: :unmute_project, constraints: { name: /.*/ }
  get "/:platform/:name/tree", to: "tree#show", constraints: { name: PROJECT_CONSTRAINT }, as: :tree
  get "/:platform/:name/score", to: "projects#score", as: :project_score, constraints: { name: /.*/ }
  get "/:platform/:name/sourcerank", to: "projects#sourcerank", as: :project_sourcerank, constraints: { name: /.*/ }
  get "/:platform/:name/versions", to: "projects#versions", as: :project_versions, constraints: { name: /.*/ }
  get "/:platform/:name/tags", to: "projects#tags", as: :project_tags, constraints: { name: /.*/ }
  get "/:platform/:name/dependents", to: "projects#dependents", as: :project_dependents, constraints: { name: /.*/ }
  get "/:platform/:name/dependent_repositories", to: "projects#dependent_repos", as: :legacy_project_dependent_repos, constraints: { name: /.*/ }
  get "/:platform/:name/dependent-repositories", to: "projects#dependent_repos", as: :project_dependent_repos, constraints: { name: /.*/ }
  get "/:platform/:name/dependent-repositories/yours", to: "projects#your_dependent_repos", as: :your_project_dependent_repos, constraints: { name: /.*/ }
  get "/:platform/:name/:number.about", to: "projects#about", as: :about_version, constraints: { number: /.*/, name: /.*/ }
  get "/:platform/:name/:number.ABOUT", to: "projects#about", constraints: { number: /.*/, name: /.*/ }
  get "/:platform/:name/:number/tree", to: "tree#show", constraints: { number: /[\w.\-%]+/, name: PROJECT_CONSTRAINT }, as: :version_tree
  get "/:platform/:name/:number", to: "projects#show", as: :version, constraints: { number: /.*/, name: /.*/ }
  get "/:platform/:name.about", to: "projects#about", as: :about_project, constraints: { name: /.*/ }
  get "/:platform/:name.ABOUT", to: "projects#about", constraints: { name: /.*/ }
  get "/:platform/:name", to: "projects#show", as: :project, constraints: { name: /.*/ }, defaults: { format: "html" }
  get "/:id", to: "platforms#show", as: :platform, constraints: { format: "html" }
end
