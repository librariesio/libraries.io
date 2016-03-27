class GithubUpdateOrgWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low
  sidekiq_options unique: :until_executed

  def perform(login)
    org = GithubOrganisation.find_by_login(login)
    org.sync if org
  end
end
