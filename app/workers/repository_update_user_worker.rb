class RepositoryUpdateUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: :owners, unique: :until_executed

  def perform(host_type, login)
    RepositoryUser.host(host_type).find_by_login(login).try(:sync)
  end
end
