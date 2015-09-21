class GithubDownloadWorker
  include Sidekiq::Worker
  sidekiq_options unique: true

  def perform(repo_id, token = nil)
    token = token || AuthToken.token
    repo = GithubRepository.find(repo_id)
    repo.update_all_info(token)
  end
end
