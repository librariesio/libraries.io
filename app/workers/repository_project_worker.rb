class RepositoryProjectWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, unique: :until_executed

  def perform(project_id)
    Project.find_by_id(project_id).try(:update_repository)
  end
end
