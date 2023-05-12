# frozen_string_literal: true

require "rails_helper"

describe GithubStarWorker do
  it "should use the low priority queue" do
    is_expected.to be_processed_in :small
  end

  it "should update from star" do
    repo_full_name = "rails/rails"
    expect(Repository).to receive(:update_from_star).with(repo_full_name)
    subject.perform(repo_full_name)
  end
end
