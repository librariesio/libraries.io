require_relative 'boot'

require 'rails/all'

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

    config.active_job.queue_adapter = :sidekiq

    config.exceptions_app = routes

    config.assets.paths << Emoji.images_path
    config.assets.precompile << "emoji/**/*.png"

    Rails::Timeago.default_options :limit => proc { 60.days.ago }, :nojs => true

    GC::Profiler.enable

    config.middleware.use Rack::Attack
    config.middleware.use Rack::Attack::RateLimit, throttle: ['api']
  end
end
