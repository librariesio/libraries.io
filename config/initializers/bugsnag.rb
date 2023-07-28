# frozen_string_literal: true

if Rails.env.production?
  Bugsnag.configure do |config|
    config.api_key = Rails.configuration.bugsnag_api_key
    config.ignore_classes << ActiveRecord::RecordNotFound
    # Temprarily uncomment this is we get a huge spike of these errors and need to investigate:
    config.ignore_classes << PackageManagerDownloadWorker::VersionUpdateFailure

    if File.exist?("#{Rails.root}/REVISION")
      config.app_version = File.read("#{Rails.root}/REVISION").strip
    elsif ENV["REVISION_ID"]
      config.app_version = ENV["REVISION_ID"]
    end
  end
end
