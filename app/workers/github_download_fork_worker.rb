class GithubDownloadForkWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, unique: :until_executed

  def perform(repo_id, token = nil)
    GithubRepository.find_by_id(repo_id).try(:download_forks, token)
  end
end
