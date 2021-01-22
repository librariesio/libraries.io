class RepositoryUpdateOrgWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, unique: :until_executed

  def perform(host_type, login)
    return if login.nil?
    RepositoryOrganisation.host(host_type).login(login).first.try(:sync)
  end
end
