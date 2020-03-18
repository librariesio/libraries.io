# frozen_string_literal: true

require "rails_helper"

describe IssuesWorker do
  it "should use the low priority queue" do
    is_expected.to be_processed_in :issues
  end

  it "should update repo for a project" do
    repo = create(:repository)
    expect(Repository).to receive(:find_by_id).with(repo.id).and_return(repo)
    expect(repo).to receive(:download_issues)
    subject.perform(repo.id)
  end
end
