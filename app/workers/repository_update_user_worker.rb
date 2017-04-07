class RepositoryUpdateUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: :owners, unique: :until_executed

  def perform(login)
    RepositoryUser.find_by_login(login).try(:sync)
  end
end
