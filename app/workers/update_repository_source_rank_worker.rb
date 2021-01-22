class UpdateRepositorySourceRankWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, unique: :until_executed

  def perform(repository_id)
    Repository.find_by_id(repository_id).try(:update_source_rank)
  end
end
