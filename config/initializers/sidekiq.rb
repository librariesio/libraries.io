require 'resolv-replace' # pure ruby DNS

# disable id so that sidekiq will work with google cloud memorystore redis
# https://github.com/mperham/sidekiq/issues/3518#issuecomment-390896088
Sidekiq.configure_server do |config|
  config.redis = { url: ENV["REDISCLOUD_URL"], id: nil }
end
Sidekiq.configure_client do |config|
  config.redis = { url: ENV["REDISCLOUD_URL"], id: nil }
end
