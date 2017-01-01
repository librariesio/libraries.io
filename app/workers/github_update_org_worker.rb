class GithubUpdateOrgWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, unique: :until_executed

  def perform(login)
    GithubOrganisation.find_by_login(login).try(:sync)
  end
end
