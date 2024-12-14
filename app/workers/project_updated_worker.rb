# frozen_string_literal: true

class ProjectUpdatedWorker
  include Sidekiq::Worker
  # retries of 10 is about 7 hours, should often be enough to fix an outage, and if it goes longer
  # than that we just miss some events. We don't want to let the backlog get too outrageous.
  #
  # Keep in mind that this retry only happens if we raise an exception, so only when we set
  # ignore_errors:false below.
  sidekiq_options queue: :small, retries: 10, lock: :until_executed

  def perform(project_id, web_hook_id)
    project = Project.find(project_id)
    web_hook = WebHook.find(web_hook_id)
    # for all_project_updates we want to be sure the webhook reries so we don't ignore errors. For
    # regular webhooks we are just best effort.
    web_hook.send_project_updated(project, ignore_errors: !web_hook.all_project_updates)
  end

  sidekiq_retries_exhausted do |job, _ex|
    Rails.logger.warn "PROJECT_UPDATED_WORKER_PERMANENT_FAILURE: Failed #{job['class']} with #{job['args']}: #{job['error_message']}"
  end
end
