# frozen_string_literal: true
class CheckStatusWorker
  include Sidekiq::Worker
  sidekiq_options queue: :status, unique: :until_executed

  def perform(project_id, removed = false)
    Project.find_by_id(project_id).try(:check_status, removed)
  end
end
