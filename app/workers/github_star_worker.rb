# frozen_string_literal: true

class GithubStarWorker
  include Sidekiq::Worker
  sidekiq_options queue: :small, unique: :until_executed

  def perform(repo_name, _token = nil)
    Repository.update_from_star(repo_name)
  end
end
