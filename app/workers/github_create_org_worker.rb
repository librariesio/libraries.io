class GithubCreateOrgWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, unique: :until_executed

  def perform(org_login)
    GithubOrganisation.create_from_github(org_login)
  end
end
