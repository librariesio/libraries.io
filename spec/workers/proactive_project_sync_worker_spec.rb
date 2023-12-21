# frozen_string_literal: true

require "rails_helper"

RSpec::Matchers.define :have_been_queued_for_project_sync do
  match do |actual|
    expect(PackageManagerDownloadWorker).to receive(:perform_async).once.with(actual.sync_classes.first.name, actual.name, any_args)
    expect(CheckStatusWorker).to receive(:perform_async).once.with(actual.id)
  end
end

RSpec::Matchers.define :have_not_been_queued_for_project_sync do
  match do |actual|
    expect(PackageManagerDownloadWorker).not_to receive(:perform_async).with(String, actual.name, any_args)
    expect(CheckStatusWorker).not_to receive(:perform_async).with(actual.id)
  end
end

RSpec.describe ProactiveProjectSyncWorker do
  it "should use the small priority queue" do
    is_expected.to be_processed_in :small
  end

  describe "#perform" do
    let!(:watched_project1) { create(:project, :npm, :watched, last_synced_at: 2.months.ago) }
    let!(:watched_project2) { create(:project, :maven, :watched, last_synced_at: 1.month.ago) }
    let!(:unwatched_project) { create(:project, :npm) }
    let!(:other_platform_project) { create(:project, :pypi) }

    it "queues targeted projects for resync" do
      expect(watched_project1).to have_been_queued_for_project_sync
      expect(watched_project2).to have_been_queued_for_project_sync
      expect(unwatched_project).to have_not_been_queued_for_project_sync
      expect(other_platform_project).to have_not_been_queued_for_project_sync

      described_class.new.perform
    end

    context "when no limit provided"
      it "operates on least recently synced projects first, within default limit" do
        stub_const("ProactiveProjectSyncWorker::DEFAULT_LIMIT", 1)

        expect(watched_project1).to have_been_queued_for_project_sync
        expect(watched_project2).to have_not_been_queued_for_project_sync

        described_class.new.perform(nil)
      end
    end

    context "with limit provided" do
      it "operates on least recently synced projects first, within limit" do
        expect(watched_project1).to have_been_queued_for_project_sync
        expect(watched_project2).to have_not_been_queued_for_project_sync

        described_class.new.perform(1)
      end
    end

    context "with recently synced project" do
      before do
        watched_project1.update(last_synced_at: 12.hours.ago)
      end

      it "excludes recently synced projects" do
        expect(watched_project1).to have_not_been_queued_for_project_sync
        expect(watched_project2).to have_been_queued_for_project_sync

        described_class.new.perform
      end
    end
  end
end
