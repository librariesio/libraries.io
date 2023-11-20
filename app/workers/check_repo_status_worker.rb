# frozen_string_literal: true

class CheckRepoStatusWorker
  include Sidekiq::Worker
  sidekiq_options queue: :status, lock: :until_executed

  def perform(host_type, repo_full_name)
    Repository.check_status(host_type, repo_full_name)
  end
end
