require 'rails_helper'

describe IssueWorker do
  it "should use the low priority queue" do
    is_expected.to be_processed_in :issues
  end

  it "should update from github" do
    repo_full_name = 'rails/rails'
    issue_number = 1
    expect(RepositoryIssue::Github).to receive(:update_from_host).with(repo_full_name, issue_number, nil)
    subject.perform(repo_full_name, issue_number)
  end
end
