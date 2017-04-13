class RepositoryUpdateOrgWorker
  include Sidekiq::Worker
  sidekiq_options queue: :owners, unique: :until_executed

  def perform(login)
    return if login.nil?
    RepositoryOrganisation.host('GitHub').find_by_login(login).try(:sync)
  end
end
