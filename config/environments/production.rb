# frozen_string_literal: true

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # Compress CSS using a preprocessor.
  config.assets.js_compressor = :uglifier
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true
  # opt /healthcheck out of SSL for load balancer healthchecks to work
  config.ssl_options = { redirect: { exclude: ->(request) { request.path =~ /healthcheck/ } } }

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :info

  # Prepend all log lines with the following tags.
  config.log_tags = [:request_id]

  # Use a different cache store in production.
  config.cache_store = :dalli_store,
                       (ENV["MEMCACHIER_SERVERS"] || "").split(","),
                       { username: ENV["MEMCACHIER_USERNAME"],
                         password: ENV["MEMCACHIER_PASSWORD"],
                         failover: true,
                         compress: true,
                         socket_timeout: 0.5,
                         socket_failure_delay: 0.1 }

  # Use a real queuing backend for Active Job (and separate queues per environment).
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "libraries_production"

  # default mail links to https
  config.host = "libraries.io"
  config.action_mailer.default_url_options = { protocol: "https", host: config.host }
  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = [I18n.default_locale]

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  config.action_mailer.smtp_settings = {
    address: "smtp.sendgrid.net",
    port: "2525",
    authentication: :plain,
    user_name: ENV["SENDGRID_USERNAME"],
    password: ENV["SENDGRID_PASSWORD"],
    domain: "heroku.com",
    enable_starttls_auto: true,
  }
  config.action_mailer.delivery_method = :smtp

  # Inserts middleware to perform automatic connection switching.
  # The `database_selector` hash is used to pass options to the DatabaseSelector
  # middleware. The `delay` is used to determine how long to wait after a write
  # to send a subsequent read to the primary.
  #
  # The `database_resolver` class is used by the middleware to determine which
  # database is appropriate to use based on the time delay.
  #
  # The `database_resolver_context` class is used by the middleware to set
  # timestamps for the last write to the primary. The resolver uses the context
  # class timestamps to determine how long to wait before reading from the
  # replica.
  #
  # By default Rails will store a last write timestamp in the session. The
  # DatabaseSelector middleware is designed as such you can define your own
  # strategy for connection switching and pass that into the middleware through
  # these configuration options.
  # config.active_record.database_selector = { delay: 2.seconds }
  # config.active_record.database_resolver = ActiveRecord::Middleware::DatabaseSelector::Resolver
  # config.active_record.database_resolver_context = ActiveRecord::Middleware::DatabaseSelector::Resolver::Session

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
      %i[rescued_error current_user remote_ip ip api_key github_event].each do |key|
        options[key] = event.payload[key] if event.payload[key]
      end
    end
  end
  # Skip the noisy exception stack traces that DebugExceptions outputs, and check Bugsnag instead.
  config.middleware.delete(ActionDispatch::DebugExceptions)

  # GCP sends proxy IP as last value of X-Forwarded-For, so we need to ensure it gets filtered out for remote_ip() method
  config.action_dispatch.trusted_proxies = ActionDispatch::RemoteIp::TRUSTED_PROXIES + ["35.244.128.241"]
end
