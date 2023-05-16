# frozen_string_literal: true

require "rails_helper"

describe CheckRepoStatusWorker do
  it "should use the low priority queue" do
    is_expected.to be_processed_in :status
  end

  it "should check repo status" do
    repo_full_name = "rails/rails"
    host_type = "GitHub"
    expect(Repository).to receive(:check_status).with(host_type, repo_full_name)
    subject.perform(host_type, repo_full_name)
  end
end
