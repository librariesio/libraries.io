class TagWorker
  include Sidekiq::Worker
  sidekiq_options queue: :small, unique: :until_executed

  def perform(repo_name, _token = nil)
    Repository.update_from_tag(repo_name)
  end
end
