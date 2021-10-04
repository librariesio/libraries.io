# frozen_string_literal: true
class CheckRepoStatusWorker
  include Sidekiq::Worker
  sidekiq_options queue: :status, unique: :until_executed

  # TODO: it's safe to remove deprecated "removed" arg
  def perform(host_type, repo_full_name, removed = false)
    Repository.check_status(host_type, repo_full_name)
  end
end
