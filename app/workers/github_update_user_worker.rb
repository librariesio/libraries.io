class GithubUpdateUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low

  def perform(login)
    user = GithubUser.find_by_login(login)
    return if user.updated_at > 2.day.ago
    user.download_from_github
    user.download_orgs
    user.download_repos
  end
end
