class VersionNotificationsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, unique: :until_executed

  def perform(version_id)
    Version.find_by_id(version_id).try(:send_notifications)
  end
end
