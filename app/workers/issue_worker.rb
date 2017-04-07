class IssueWorker
  include Sidekiq::Worker
  sidekiq_options queue: :issues, unique: :until_executed

  def perform(name_with_owner, issue_number, token = nil)
    Issue.update_from_github(name_with_owner, issue_number, token)
  end
end
