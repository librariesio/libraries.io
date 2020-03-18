# frozen_string_literal: true

require "rails_helper"

describe GithubHookWorker do
  it "should use the critical priority queue" do
    is_expected.to be_processed_in :critical
  end

  it "should update from hook" do
    github_id = 1
    sender_id = 2
    expect(Repository).to receive(:update_from_hook).with(github_id, sender_id)
    subject.perform(github_id, sender_id)
  end
end
