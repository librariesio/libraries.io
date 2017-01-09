class RepositoryTreeResolverWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def perform(repository_id, date = nil)
    GithubRepository.find_by_id(repository_id).try(:load_dependencies_tree, date)
  end
end
