# frozen_string_literal: true

class CheckStatusWorker
  include Sidekiq::Worker
  sidekiq_options queue: :status, lock: :until_and_while_executing, lock_ttl: 10.minutes.to_i

  def perform(project_id)
    Project.find_by_id(project_id).try(:check_status)
  rescue Project::CheckStatusRateLimited
    # Don't give up when we are rate-limited: we would get 429'ed when we are checking many statuses at once,
    # so detect these and retry them within the next 10-60 minutes.
    CheckStatusWorker.perform_in(rand(10..59), project_id)
  end
end
