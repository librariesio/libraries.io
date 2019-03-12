class PackageManagerDownloadWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, unique: :until_executed

  def perform(class_name, name)
    return unless class_name.present?
    Rails.logger.info("Beginning update for #{class_name}/#{name}")
    "PackageManager::#{class_name}".constantize.update(name)
  end
end
