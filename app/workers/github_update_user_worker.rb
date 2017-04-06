class GithubUpdateUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: :owners, unique: :until_executed

  def perform(login)
    GithubUser.find_by_login(login).try(:sync)
  end
end
