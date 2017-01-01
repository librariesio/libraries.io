require 'rails_helper'

describe CheckRepoStatusWorker do
  it "should use the low priority queue" do
    is_expected.to be_processed_in :low
  end

  it "should check repo status" do
    repo_full_name = 'rails/rails'
    removed = true
    expect(GithubRepository).to receive(:check_status).with(repo_full_name, removed)
    subject.perform(repo_full_name, removed)
  end
end
