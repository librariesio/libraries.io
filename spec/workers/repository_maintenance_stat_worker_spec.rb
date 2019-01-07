require 'rails_helper'

describe RepositoryMaintenanceStatWorker do
  let!(:repository) { create(:repository) }

  it "should use the medium priority queue by default" do
    is_expected.to be_processed_in :repo_maintenance_stat
  end

  it "should be unique" do
    is_expected.to be_unique
  end

  it "should gather stats for the repository" do
    expect(GatherRepositoryMaintenanceStats).to receive(:gather_stats).with(repository)
    subject.perform(repository.id)
  end
end
