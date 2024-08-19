# frozen_string_literal: true

class RepositoryDownloadWorker
  include Sidekiq::Worker
  sidekiq_options queue: :repo, lock: :until_and_while_executing, lock_ttl: 10.minutes.to_i

  def perform(repo_id, token = nil)
    Repository.find_by_id(repo_id).try(:update_all_info, token)
  end
end
