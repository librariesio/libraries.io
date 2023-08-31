# frozen_string_literal: true

require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
require "sprockets/railtie"
require "graphql/client/http"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Libraries
  class Application < Rails::Application
    config.load_defaults 6.1
    config.autoloader = :zeitwerk

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Initialize GraphQL client for Github API v4
    # Load schema from previous Github API schema dump
    Schema = Application.root.join("config/github_graphql_schema.json").to_s

    # Create new client from schema to parse queries with
    # Actual client for querying should come from AuthToken
    Client = GraphQL::Client.new(schema: Schema)
    Application.config.graphql = ActiveSupport::OrderedOptions.new
    Application.config.graphql.client = Client
    Application.config.graphql.schema = Schema

    config.active_job.queue_adapter = :sidekiq

    config.exceptions_app = routes

    Rails::Timeago.default_options limit: proc { 60.days.ago }, nojs: true, format: proc { |time, _options| time.strftime("%b %e, %Y") }

    # GC::Profiler.enable

    config.middleware.use Rack::Attack
    config.middleware.use Rack::Attack::RateLimit, throttle: ["api"]

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins "*"
        resource(/^\/api\/.+/,
                 headers: :any,
                 methods: %i[get post patch put delete options head], expose: %w[total per-page],
                 max_age: 86400)
      end
    end

    # Env-based config
    config.github_public_key = ENV.fetch("GITHUB_PUBLIC_KEY", nil)
    config.github_public_secret = ENV.fetch("GITHUB_PUBLIC_SECRET", nil)
    config.github_private_key = ENV.fetch("GITHUB_PRIVATE_KEY", nil)
    config.github_private_secret = ENV.fetch("GITHUB_PRIVATE_SECRET", nil)
    config.github_key = ENV.fetch("GITHUB_KEY", nil)
    config.github_secret = ENV.fetch("GITHUB_SECRET", nil)
    config.bitbucket_key = ENV.fetch("BITBUCKET_KEY", nil)
    config.gitlab_key = ENV.fetch("GITLAB_KEY", nil)
    config.gitlab_application_id = ENV.fetch("GITLAB_APPLICATION_ID", nil)
    config.gitlab_secret = ENV.fetch("GITLAB_SECRET", nil)
    config.bugsnag_api_key = ENV.fetch("BUGSNAG_API_KEY", nil)
    config.bitbucket_application_id = ENV.fetch("BITBUCKET_APPLICATION_ID", nil)
    config.bitbucket_secret = ENV.fetch("BITBUCKET_SECRET", nil)
    config.ga_analytics_id = ENV.fetch("GA_ANALYTICS_ID", nil)
    config.gtm_id = ENV.fetch("GTM_ID", nil)
    config.tidelift_api_key = ENV.fetch("TIDELIFT_API_KEY", nil)
  end
end
