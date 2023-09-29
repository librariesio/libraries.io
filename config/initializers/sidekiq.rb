# frozen_string_literal: true

require "resolv-replace" # pure ruby DNS
require "sidekiq_enqueue_logger"

# Just adds "sidekiq=true" to the default Pretty formatter, to make aggregating simpler.
class StructuredLogSidekiqFormatter < Sidekiq::Logger::Formatters::Base
  def call(severity, time, _program_name, message)
    "#{time.utc.iso8601(3)} sidekiq=true pid=#{::Process.pid} tid=#{tid}#{format_context} #{severity}: #{message}\n"
  end
end

Sidekiq.configure_server do |config|
  # this is needed for the datadog ruby profiler; for the web app
  # it's in config.ru, but sidekiq doesn't load that.
  require "datadog/profiling/preload"

  config.logger.formatter = TideliftSidekiqLogFormatter.new

  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
  end

  # ensure that jobs-that-enqueue-jobs get the client middleware too
  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
    chain.add SidekiqEnqueueLogger::Middleware::Client unless Rails.env.test?
  end

  # disable id so that sidekiq will work with google cloud memorystore redis
  # https://github.com/mperham/sidekiq/issues/3518#issuecomment-390896088
  config.redis = { url: ENV.fetch("REDISCLOUD_URL", nil), id: nil }

  SidekiqUniqueJobs::Server.configure(config)
end

Sidekiq.configure_client do |config|
  config.logger.formatter = StructuredLogSidekiqFormatter.new

  # disable id so that sidekiq will work with google cloud memorystore redis
  # https://github.com/mperham/sidekiq/issues/3518#issuecomment-390896088
  config.redis = { url: ENV.fetch("REDISCLOUD_URL", nil), id: nil }

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
    chain.add SidekiqEnqueueLogger::Middleware::Client unless Rails.env.test?
  end
end

Sidekiq.default_job_options = {
  backtrace: true,
}

Sidekiq.default_worker_options = {
  backtrace: true,
}

SidekiqUniqueJobs.configure do |config|
  config.enabled = true # !Rails.env.test?
  config.lock_info = true
end

Marginalia::SidekiqInstrumentation.enable!
