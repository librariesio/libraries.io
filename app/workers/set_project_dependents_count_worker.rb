# frozen_string_literal: true

class SetProjectDependentsCountWorker
  include Sidekiq::Worker
  sidekiq_options queue: :small, lock: :until_executed

  def perform(project_id)
    Project.find_by_id(project_id).try(:set_dependents_count)
  end
end
