class TagNotificationsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, unique: :until_executed

  def perform(tag_id)
    GithubTag.find_by_id(tag_id).try(:send_notifications)
  end
end
