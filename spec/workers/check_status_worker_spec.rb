# frozen_string_literal: true

require "rails_helper"

describe CheckStatusWorker do
  it "should use the low priority queue" do
    is_expected.to be_processed_in :status
  end

  it "should check repo status" do
    VCR.use_cassette("project/check_status/rails") do
      project = create(:project, name: "rails")
      expect(Project).to receive(:find_by_id).with(project.id).and_return(project)
      subject.perform(project.id)
    end
  end

  it "should rescue CheckStatusRateLimited and retry later" do
    project = create(:project, name: "rails")
    expect(Project).to receive(:find_by_id).with(project.id).and_return(project)
    expect(project).to receive(:check_status).and_raise(Project::CheckStatusRateLimited)
    expect(project.reload.status_checked_at).to be_nil

    subject.perform(project.id)
  end
end
