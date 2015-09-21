class GithubCreateWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, unique: true

  def perform(repo_name, token = nil)
    token = token || AuthToken.token
    GithubRepository.create_from_github(repo_name, token)
  end
end
