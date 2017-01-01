class CheckRepoStatusWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, unique: :until_executed

  def perform(repo_full_name, removed = false)
    GithubRepository.check_status(repo_full_name, removed)
  end
end
