class GithubTagWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, unique: :until_executed

  def perform(repo_name, token = nil)
    token = token || AuthToken.token

    github_repository = GithubRepository.find_by_full_name(repo_name)
    if github_repository
      github_repository.download_tags(token)
    else
      GithubRepository.create_from_github(repo_name, token)
    end
  end
end
