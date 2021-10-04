# frozen_string_literal: true
class CheckStatusWorker
  include Sidekiq::Worker
  sidekiq_options queue: :status, unique: :until_executed

  # TODO: it's now safe to remove deprecated 'removed' arg
  def perform(project_id, removed = false)
    Project.find_by_id(project_id).try(:check_status)
  end
end
