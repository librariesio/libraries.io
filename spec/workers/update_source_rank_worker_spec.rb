require 'rails_helper'

describe UpdateSourceRankWorker do
  it "should use the low priority queue" do
    is_expected.to be_processed_in :sourcerank
  end

  it "should update sourcerank for a project" do
    project = create(:project)
    expect(Project).to receive(:find_by_id).with(project.id).and_return(project)
    expect(project).to receive(:update_source_rank)
    subject.perform(project.id)
  end
end
