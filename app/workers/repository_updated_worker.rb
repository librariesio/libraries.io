# frozen_string_literal: true

class RepositoryUpdatedWorker
  include Sidekiq::Worker
  # retries of 10 is about 7 hours, should often be enough to fix an outage, and
  # if it goes longer than that we just miss some events. We don't want to let
  # the backlog get too outrageous.
  sidekiq_options queue: :small, retries: 10, lock: :until_executed

  def perform(repository_id, web_hook_id)
    repository = Repository.find(repository_id)
    web_hook = WebHook.find(web_hook_id)
    web_hook.send_repository_updated(repository, ignore_errors: true)
  end

  sidekiq_retries_exhausted do |job, _ex|
    Rails.logger.warn "Failed #{job['class']} with #{job['args']}: #{job['error_message']}"
  end
end
