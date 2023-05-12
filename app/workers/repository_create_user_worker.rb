# frozen_string_literal: true

class RepositoryCreateUserWorker
  include Sidekiq::Worker
  sidekiq_options queue: :owners, unique: :until_executed

  def perform(host_type, user_login)
    RepositoryOwner.const_get(host_type.capitalize).download_user_from_host(host_type, user_login)
  end
end
