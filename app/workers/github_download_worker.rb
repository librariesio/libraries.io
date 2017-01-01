class GithubDownloadWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, unique: :until_executed

  def perform(repo_id, token = nil)
    GithubRepository.find_by_id(repo_id).try(:update_all_info, token)
  end
end
