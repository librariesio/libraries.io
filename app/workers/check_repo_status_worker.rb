# frozen_string_literal: true

class CheckRepoStatusWorker
  include Sidekiq::Worker
  sidekiq_options queue: :status, lock: :until_executed

  def perform(host_type, repo_full_name)
    repo = Repository
      .includes(:projects)
      .host(host_type)
      .find_by_full_name(repo_full_name)
    repo.check_status
  end
end
