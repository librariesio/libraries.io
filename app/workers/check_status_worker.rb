# frozen_string_literal: true

class CheckStatusWorker
  include Sidekiq::Worker
  sidekiq_options queue: :status, lock: :until_and_while_executing, lock_ttl: 10.minutes.to_i

  def perform(project_id)
    project = Project.find_by_id(project_id)
    project.try(:check_status)
  rescue Project::CheckStatusInternallyRateLimited, Project::CheckStatusExternallyRateLimited => e
    # status_check_at is eagerly updated in Project#check_status, so reset it to nil
    # so we can tell if it was throttled.
    project.update_column(:status_checked_at, nil)
    if e.retry_after_seconds
      CheckStatusWorker.perform_in(e.retry_after_seconds.seconds.from_now, project.id)
    end
  end
end
