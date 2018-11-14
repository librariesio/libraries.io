if Rails.env.production?
  Bugsnag.configure do |config|
    config.api_key = ENV['BUGSNAG_API_KEY']
    config.ignore_classes << ActiveRecord::RecordNotFound
  end
end
