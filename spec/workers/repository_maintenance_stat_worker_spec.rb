# frozen_string_literal: true

require "rails_helper"

# Oct 5 2023 temporarily disabled maintenance stat worker
xdescribe RepositoryMaintenanceStatWorker do
  let!(:repository) { create(:repository) }

  before do
    Sidekiq::Worker.clear_all
  end

  it "should use the medium priority queue by default" do
    is_expected.to be_processed_in :repo_maintenance_stat
  end

  it "should gather stats for the repository" do
    expect(Repository).to receive(:find).with(repository.id).and_return(repository)
    expect(repository).to receive(:gather_maintenance_stats).and_return([])
    subject.perform(repository.id)
  end

  it "should queue jobs in high priority" do
    expect(Sidekiq::Queues["repo_maintenance_stat_high"].size).to eql 0
    expect(RepositoryMaintenanceStatWorker.jobs.size).to eql 0

    RepositoryMaintenanceStatWorker.enqueue(repository.id, priority: :high)

    expect(RepositoryMaintenanceStatWorker.jobs.size).to eql 1
    expect(Sidekiq::Queues["repo_maintenance_stat_high"].size).to eql 1
  end

  it "should queue jobs in low priority" do
    expect(Sidekiq::Queues["repo_maintenance_stat_low"].size).to eql 0
    expect(RepositoryMaintenanceStatWorker.jobs.size).to eql 0

    RepositoryMaintenanceStatWorker.enqueue(repository.id, priority: :low)

    expect(RepositoryMaintenanceStatWorker.jobs.size).to eql 1
    expect(Sidekiq::Queues["repo_maintenance_stat_low"].size).to eql 1
  end

  context "with unsupported repository host_type" do
    let!(:repository) { create(:repository, host_type: "gitlab") }

    it "should gracefully not gather stats" do
      # call directly
      expect(repository.gather_maintenance_stats).to eql []

      # call worker and fail on error
      expect(Repository).to receive(:find).with(repository.id).and_return(repository)
      subject.perform(repository.id)
    end
  end
end
