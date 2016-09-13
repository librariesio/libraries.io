class GithubDownloadWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, unique: :until_executed

  def perform(repo_id, token = nil)
    token = token || AuthToken.token
    repo = GithubRepository.find_by_id(repo_id)
    repo.update_all_info(token) if repo
  end
end
