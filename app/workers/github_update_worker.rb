class GithubUpdateWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, unique: :until_executed

  def perform(repo_name, token = nil)
    Repository.update_from_name(repo_name, token)
  end
end
