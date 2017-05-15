class RepositoryCreateOrgWorker
  include Sidekiq::Worker
  sidekiq_options queue: :owners, unique: :until_executed

  def perform(org_login)
    RepositoryOwner::Base.download_org_from_host('GitHub', org_login)
  end
end
