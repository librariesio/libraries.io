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
    config.add_on_breadcrumb(proc do |breadcrumb|
      if breadcrumb.metadata[:path].present?
        cleaned_path = begin
          Bugsnag.cleaner.clean_url(breadcrumb.metadata[:path])
        rescue StandardError => e
          Rails.logger.info "[BUGSNAG FILTERING] error='#{e.class}' message='#{e.message}'"
          nil
        end
        breadcrumb.metadata[:path] = cleaned_path if cleaned_path
      end
    end)
  end
end
