# frozen_string_literal: true

class RepositoryCreateOrgWorker
  include Sidekiq::Worker
  sidekiq_options queue: :owners, unique: :until_executed

  def perform(host_type, org_login)
    RepositoryOwner.const_get(host_type.capitalize).download_org_from_host(host_type, org_login)
  end
end
