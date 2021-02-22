# frozen_string_literal: true
class IssueWorker
  include Sidekiq::Worker
  sidekiq_options queue: :issues, unique: :until_executed

  def perform(host_type, name_with_owner, issue_number, type, token = nil)
    RepositoryIssue::Base.update(host_type, name_with_owner, issue_number, type, token)
  end
end
