# frozen_string_literal: true

require "rails_helper"

describe CheckRepoStatusWorker do
  it "should use the low priority queue" do
    is_expected.to be_processed_in :status
  end

  it "should check repo status" do
    repo = create(:repository, host_type: "GitHub", full_name: "rails/rails")

    expect_any_instance_of(Repository).to receive(:check_status)
    subject.perform(repo.host_type, repo.full_name)
  end
end
