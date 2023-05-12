# frozen_string_literal: true

class CheckStatusWorker
  include Sidekiq::Worker
  sidekiq_options queue: :status, unique: :until_executed

  def perform(project_id, deprecated_or_removed = false)
    Project.find_by_id(project_id).try(:check_status, deprecated_or_removed)
  end
end
