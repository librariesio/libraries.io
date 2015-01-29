uri = ENV['REDISCLOUD_URL'] || 'redis://localhost:6379/'
REDIS = Redis.new(url: uri, driver: :hiredis)
