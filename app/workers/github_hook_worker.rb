# frozen_string_literal: true

class GithubHookWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, unique: :until_executed

  def perform(github_id, sender_id)
    Repository.update_from_hook(github_id, sender_id)
  end
end
