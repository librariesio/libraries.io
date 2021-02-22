# frozen_string_literal: true
class RepositoryProjectWorker
  include Sidekiq::Worker
  sidekiq_options queue: :repo, unique: :until_executed

  def perform(project_id)
    Project.find_by_id(project_id).try(:update_repository)
  end
end
