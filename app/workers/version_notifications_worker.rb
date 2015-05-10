class VersionNotificationsWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :critical

  def perform(version_id)
    Version.find(version_id).send_notifications
  end
end
