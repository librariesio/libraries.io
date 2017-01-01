require 'rails_helper'

describe CheckStatusWorker do
  it "should use the low priority queue" do
    is_expected.to be_processed_in :low
  end

  it "should check repo status" do
    project_id = 1
    platform = 'Rubygems'
    project_name = 'rails'
    removed = false
    expect(Project).to receive(:check_status).with(project_id, platform, project_name, removed)
    subject.perform(project_id, platform, project_name, removed)
  end
end
