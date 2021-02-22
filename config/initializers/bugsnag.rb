# frozen_string_literal: true
if Rails.env.production?
  Bugsnag.configure do |config|
    config.api_key = ENV['BUGSNAG_API_KEY']
    config.ignore_classes << ActiveRecord::RecordNotFound

    if File.exist?("#{Rails.root}/REVISION")
      config.app_version = File.read("#{Rails.root}/REVISION").strip
    elsif ENV['GIT_COMMIT']
      config.app_version = ENV['GIT_COMMIT']
    end
  end
end
