require 'rails_helper'

describe GithubUpdateWorker do
  it "should use the low priority queue" do
    is_expected.to be_processed_in :low
  end

  it "should update repo" do
    repo_full_name = 'rails/rails'
    expect(Repository).to receive(:update_from_name).with(repo_full_name, nil)
    subject.perform(repo_full_name)
  end
end
