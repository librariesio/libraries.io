class TagNotificationsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, unique: true

  def perform(tag_id)
    GithubTag.find(tag_id).send_notifications
  end
end
