# frozen_string_literal: true

class ProjectUpdatedWorker
  include Sidekiq::Worker
  # retries of 10 is about 7 hours, should often be enough to fix an outage, and
  # if it goes longer than that we just miss some events. We don't want to let
  # the backlog get too outrageous.
  sidekiq_options queue: :small, retries: 10, unique: :until_executed

  def perform(project_id, web_hook_id)
    project = Project.find(project_id)
    web_hook = WebHook.find(web_hook_id)
    web_hook.send_project_updated(project)
  end
end
