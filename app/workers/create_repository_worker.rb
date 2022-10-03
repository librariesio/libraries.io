# frozen_string_literal: true
class CreateRepositoryWorker
  include Sidekiq::Worker
  sidekiq_options queue: :repo, unique: :until_executed

  def perform(host_type, repo_name, token = nil)
    return unless repo_name.present?
    Repository.create_from_host(host_type, repo_name, token)
    GC.start
  end
end
