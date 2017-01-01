class GithubStarWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, unique: :until_executed

  def perform(repo_name, token = nil)
    GithubRepository.update_from_star(repo_name, token)
  end
end
