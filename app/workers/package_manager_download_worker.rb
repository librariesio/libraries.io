class PackageManagerDownloadWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, unique: :until_executed

  def perform(class_name, name)
    return unless class_name.present?
    "PackageManager::#{class_name}".constantize.update(name)
  end
end
