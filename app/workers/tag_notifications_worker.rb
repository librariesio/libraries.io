# frozen_string_literal: true

class TagNotificationsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, lock: :until_executed

  def perform(tag_id)
    Tag.find_by_id(tag_id).try(:send_notifications)
  end
end
