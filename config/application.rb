# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "sprockets/railtie"
require "graphql/client/http"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Libraries
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # config.autoload_paths << Rails.root.join('lib')

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # config.middleware.use Rack::Deflater

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

    config.assets.paths << Emoji.images_path
    config.assets.precompile << "emoji/**/*.png"

    Rails::Timeago.default_options limit: proc { 60.days.ago }, nojs: true, format: proc { |time, _options| time.strftime("%b %e, %Y") }

    # GC::Profiler.enable

    config.middleware.use Rack::Attack
    config.middleware.use Rack::Attack::RateLimit, throttle: ["api"]

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins "*"
        resource /^\/api\/.+/,
                 headers: :any,
                 methods: %i[get post patch put delete options head],
                 max_age: 86400
      end
    end
  end
end
