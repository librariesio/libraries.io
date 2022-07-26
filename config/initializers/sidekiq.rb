# frozen_string_literal: true
require 'resolv-replace' # pure ruby DNS

# disable id so that sidekiq will work with google cloud memorystore redis
# https://github.com/mperham/sidekiq/issues/3518#issuecomment-390896088
Sidekiq.configure_server do |config|
  config.redis = { url: ENV["REDISCLOUD_URL"], id: nil }
  config.server_middleware do |chain|
    chain.add Sidekiq::GoogleCloudTraceMiddleware, capture_stack: false
  end
end
Sidekiq.configure_client do |config|
  config.redis = { url: ENV["REDISCLOUD_URL"], id: nil }
end

Sidekiq.default_worker_options = {
  backtrace: true,
}

SidekiqUniqueJobs.configure do |config|
  config.enabled = !Rails.env.test?
end
Marginalia::SidekiqInstrumentation.enable!
