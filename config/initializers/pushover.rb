Pushover.configure do |config|
  config.user = ENV['PUSHOVER_USER_KEY']
  config.token = ENV['PUSHOVER_API_KEY']
end
