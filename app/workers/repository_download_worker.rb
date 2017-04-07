class RepositoryDownloadWorker
  include Sidekiq::Worker
  sidekiq_options queue: :repo, unique: :until_executed

  def perform(repo_id, token = nil)
    Repository.find_by_id(repo_id).try(:update_all_info, token)
  end
end
