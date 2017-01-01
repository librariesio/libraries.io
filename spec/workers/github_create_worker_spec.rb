require 'rails_helper'

describe GithubCreateWorker do
  it "should use the low priority queue" do
    is_expected.to be_processed_in :low
  end

  it "should create from github" do
    repo_name = 'rails/rails'
    expect(GithubRepository).to receive(:create_from_github).with(repo_name, nil)
    subject.perform(repo_name)
  end
end
