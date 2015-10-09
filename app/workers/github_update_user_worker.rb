class GithubUpdateUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low
  sidekiq_options unique: true

  def perform(login)
    user = GithubUser.find_by_login(login)
    user.download_from_github
    user.download_orgs
    user.download_repos
    user.touch
  end
end
