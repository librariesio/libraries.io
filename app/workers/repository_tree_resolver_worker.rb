# frozen_string_literal: true

class RepositoryTreeResolverWorker
  include Sidekiq::Worker
  sidekiq_options queue: :tree, lock: :until_executed

  def perform(repository_id, date = nil)
    Repository.find_by_id(repository_id).try(:load_dependencies_tree, date)
  end
end
