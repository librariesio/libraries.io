# frozen_string_literal: true
class RepositoryUpdateOrgWorker
  include Sidekiq::Worker
  sidekiq_options queue: :owners, unique: :until_executed

  def perform(host_type, login)
    return if login.nil?
    RepositoryOrganisation.host(host_type).login(login).first.try(:sync)
  end
end
