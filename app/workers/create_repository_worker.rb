class CreateRepositoryWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, unique: :until_executed

  def perform(repo_name, token = nil)
    Repository.create_from_github(repo_name, token)
  end
end
