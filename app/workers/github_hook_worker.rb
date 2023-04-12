# frozen_string_literal: true
class GithubHookWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, unique: :until_executed

  def perform(github_id, sender_id)
    # some events like "push" may not always have the "sender" field, e.g. PR merge commits
    return if sender_id.blank?

    Repository.update_from_hook(github_id, sender_id)
  end
end
