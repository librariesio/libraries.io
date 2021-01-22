class CheckRepoStatusWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, unique: :until_executed

  def perform(host_type, repo_full_name, removed = false)
    Repository.check_status(host_type, repo_full_name, removed)
  end
end
