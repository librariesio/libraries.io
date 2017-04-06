class GithubUpdateOrgWorker
  include Sidekiq::Worker
  sidekiq_options queue: :owners, unique: :until_executed

  def perform(login)
    return if login.nil?
    GithubOrganisation.find_by_login(login).try(:sync)
  end
end
