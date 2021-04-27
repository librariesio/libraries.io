# frozen_string_literal: true

class ProjectTagsUpdateWorker
  include Sidekiq::Worker
  sidekiq_options queue: :small, unique: :until_executed

  def perform(project_id)
    Project.find(project_id).update_tags
  end
end
