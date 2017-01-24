class UpdateRepositorySourceRankWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, unique: :until_executed

  def perform(github_repository_id)
    Repository.find_by_id(github_repository_id).try(:update_source_rank)
  end
end
