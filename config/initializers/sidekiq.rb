# frozen_string_literal: true

require "resolv-replace" # pure ruby DNS
require "sidekiq_enqueue_logger"

# Just adds "sidekiq=true" to the default Pretty formatter, to make aggregating simpler.
class StructuredLogSidekiqFormatter < Sidekiq::Logger::Formatters::Base
  def call(severity, time, _program_name, message)
    "#{time.utc.iso8601(3)} sidekiq=true pid=#{::Process.pid} tid=#{tid}#{format_context} #{severity}: #{message}\n"
  end
end

# Use this exception to retry Sidekiq jobs without sounding Bugsnag alerts
class SidekiqQuietRetryError < StandardError; end

Sidekiq.configure_server do |config|
  # this is needed for the datadog ruby profiler; for the web app
  # it's in config.ru, but sidekiq doesn't load that.
  require "datadog/profiling/preload"

  config.logger.formatter = StructuredLogSidekiqFormatter.new

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
  # disable id so that sidekiq will work with google cloud memorystore redis
  # https://github.com/mperham/sidekiq/issues/3518#issuecomment-390896088
  config.redis = { url: ENV.fetch("REDISCLOUD_URL", nil), id: nil }

  config.logger.formatter = StructuredLogSidekiqFormatter.new

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

SidekiqUniqueJobs.reflect do |on|
  # Some useful logs via https://github.com/mhenrixon/sidekiq-unique-jobs/blob/main/UPGRADING.md

  # This job is skipped because it is a duplicate
  on.duplicate do |job_hash|
    logger.warn(job_hash.merge(message: "SidekiqUniqueJobs: Duplicate Job"))
  end

  # Failed to acquire lock in a timely fashion
  on.lock_failed do |job_hash|
    logger.warn(job_hash.merge(message: "SidekiqUniqueJobs: Lock failed"))
  end

  # When your conflict strategy is to reschedule and it failed
  on.reschedule_failed do |job_hash|
    logger.debug(job_hash.merge(message: "SidekiqUniqueJobs: Reschedule failed"))
  end

  # You asked to wait for a lock to be achieved but we timed out waiting
  on.timeout do |job_hash|
    logger.warn(job_hash.merge(message: "SidekiqUniqueJobs: Lock timeout"))
  end

  # Unlock failed! Not good
  on.unlock_failed do |job_hash|
    logger.warn(job_hash.merge(message: "SidekiqUniqueJobs: Unlock failed"))
  end
end

Marginalia::SidekiqInstrumentation.enable!
