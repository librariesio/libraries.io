# frozen_string_literal: true

require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing
  config.server_timing = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join("tmp", "caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}",
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  config.host = "localhost"
  config.action_mailer.default_url_options = { host: config.host, port: 3000 }

  # Logging options
  logger = ActiveSupport::Logger.new($stdout)
  logger.formatter = proc do |severity, datetime, _progname, msg|
    date_format = datetime.strftime("%Y-%m-%dT%H:%M:%S.%L")
    "#{date_format} #{severity} #{msg}\n"
  end
  config.logger = ActiveSupport::TaggedLogging.new(logger)
  config.active_record.logger = nil # disables SQL logging
  config.lograge.enabled = true
  config.lograge.ignore_actions = ["HealthcheckController#index"]
  config.lograge.formatter = Lograge::Formatters::Json.new
  # "api_key" is the one from params, which we might overwrite beneath with our own "api_key" object.
  params_exceptions = %w[controller action format id api_key].freeze
  config.lograge.custom_options = lambda do |event|
    {}.tap do |options|
      options[:params] = event.payload[:params].except(*params_exceptions)
      # extra keys that we want to log. Add these in the append_info_to_payload() overrided controller methods.
      %i[rescued_error current_user remote_ip ip api_key github_event user_agent referer].each do |key|
        options[key] = event.payload[key] if event.payload[key]
      end
    end
  end
end
