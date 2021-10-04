# frozen_string_literal: true
require 'rails_helper'

describe CheckStatusWorker do
  it "should use the low priority queue" do
    is_expected.to be_processed_in :status
  end

  it "should check repo status" do
    project = create(:project)
    removed = false
    expect(Project).to receive(:find_by_id).with(project.id).and_return(project)
    expect(project).to receive(:check_status)
    subject.perform(project.id)
  end
end
