require 'rails_helper'

describe IssueWorker do
  it "should use the low priority queue" do
    is_expected.to be_processed_in :issues
  end

  it "should update from github" do
    repo_full_name = 'rails/rails'
    issue_number = 1
    host_type = 'GitHub'
    type = 'issue'
    token = nil
    expect(RepositoryIssue::Base).to receive(:update).with(host_type, repo_full_name, issue_number, type, token)
    subject.perform(host_type, repo_full_name, issue_number, type, token)
  end
end
