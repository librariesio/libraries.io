class GithubDownloadForkWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :low

  def perform(repo_id, token = nil)
    token = token || AuthToken.token
    repo = GithubRepository.find(repo_id)
    repo.download_forks(token)
  end
end
