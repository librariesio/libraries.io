require 'rails_helper'

describe RepositoryMaintenanceStatWorker do
  let!(:repository) { create(:repository) }

  before do
    Sidekiq::Worker.clear_all
  end

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

  it "should queue jobs in high priority" do
    # need to disable the queue locking for tests to work with Sidekiq mocking
    SidekiqUniqueJobs.use_config(enabled: false) do
      expect(Sidekiq::Queues["repo_maintenance_stat_high"].size).to eql 0
      expect(RepositoryMaintenanceStatWorker.jobs.size).to eql 0

      RepositoryMaintenanceStatWorker.queue(repository.id, priority: :high)
    
      expect(RepositoryMaintenanceStatWorker.jobs.size).to eql 1
      expect(Sidekiq::Queues["repo_maintenance_stat_high"].size).to eql 1
    end
  end

  it "should queue jobs in low priority" do
    # need to disable the queue locking for tests to work with Sidekiq mocking
    SidekiqUniqueJobs.use_config(enabled: false) do
      expect(Sidekiq::Queues["repo_maintenance_stat_low"].size).to eql 0
      expect(RepositoryMaintenanceStatWorker.jobs.size).to eql 0

      RepositoryMaintenanceStatWorker.queue(repository.id, priority: :low)
    
      expect(RepositoryMaintenanceStatWorker.jobs.size).to eql 1
      expect(Sidekiq::Queues["repo_maintenance_stat_low"].size).to eql 1
    end
  end
end
