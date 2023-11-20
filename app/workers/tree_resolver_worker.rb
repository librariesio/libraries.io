# frozen_string_literal: true

class TreeResolverWorker
  include Sidekiq::Worker
  sidekiq_options queue: :tree, lock: :until_executed

  def perform(version_id, kind, date = nil)
    Version.find_by_id(version_id).try(:load_dependencies_tree, kind, date)
  end
end
