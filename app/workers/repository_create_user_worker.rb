class RepositoryCreateUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: :owners, unique: :until_executed

  def perform(host_type, org_login)
    RepositoryOwner::Base.download_user_from_host(host_type, org_login)
  end
end
