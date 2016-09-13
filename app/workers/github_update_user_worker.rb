class GithubUpdateUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low
  sidekiq_options unique: :until_executed

  def perform(login)
    user = GithubUser.find_by_login(login)
    user.sync if user
  end
end
