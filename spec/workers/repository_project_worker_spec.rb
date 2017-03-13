require 'rails_helper'

describe RepositoryProjectWorker do
  it "should use the low priority queue" do
    is_expected.to be_processed_in :low
  end

  it "should update repo for a project" do
    project = create(:project)
    expect(Project).to receive(:find_by_id).with(project.id).and_return(project)
    expect(project).to receive(:update_repository)
    subject.perform(project.id)
  end
end
