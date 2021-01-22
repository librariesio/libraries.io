require 'rails_helper'

describe RepositoryMaintenanceStatWorker do
  let!(:repository) { create(:repository) }

  before do
    Sidekiq::Worker.clear_all
  end

  it "should gather stats for the repository" do
    expect(Repository).to receive(:find).with(repository.id).and_return(repository)
    expect(repository).to receive(:gather_maintenance_stats).and_return([])
    subject.perform(repository.id)
  end

  context "with unsupported repository host_type" do
    let!(:repository) { create(:repository, host_type: 'gitlab') }

    it "should gracefully not gather stats" do
      # call directly
      expect(repository.gather_maintenance_stats).to eql []

      # call worker and fail on error
      expect(Repository).to receive(:find).with(repository.id).and_return(repository)
      subject.perform(repository.id)
    end
  end
end
