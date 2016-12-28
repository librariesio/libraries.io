class UpdateRepositorySourceRankWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :low, unique: :until_executed

  def perform(github_repository_id)
    repo = GitHubRepository.find_by_id(github_repository_id)
    repo.update_source_rank if repo && repo.updated_at.present? && repo.updated_at < 1.day.ago
  end
end
