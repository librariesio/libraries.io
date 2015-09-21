class GithubCreateOrgWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, unique: true

  def perform(org_login)
    GithubOrganisation.create_from_github(org_login)
  end
end
