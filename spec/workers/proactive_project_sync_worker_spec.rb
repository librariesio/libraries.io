# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProactiveProjectSyncWorker do
  it "should use the ___ priority queue" do
    is_expected.to be_processed_in :small
  end

  describe "#project_query" do
    subject(:projects) { described_class.new.projects_query }

    let!(:watched_project) { create(:project, :npm, :watched) }
    let!(:unwatched_project) { create(:project, :npm) }
    let!(:other_platform_project) { create(:project, :pypi) }

    it "targets only projects that are watched and belong to given platform" do
      expect(projects).to match([watched_project])
      expect(projects).not_to include(unwatched_project)
      expect(projects).not_to include(other_platform_project)
    end

    context "with recently synced project" do
      before do
        watched_project.update(last_synced_at: 12.hours.ago)
      end

      it "excludes recently synced projects" do
        expect(projects).to be_empty
      end
    end
  end

  describe "#perform" do
    let!(:watched_project1) { create(:project, :npm, :watched) }
    let!(:watched_project2) { create(:project, :maven, :watched) }
    let!(:unwatched_project) { create(:project, :npm) }

    it "queues targeted projects for resync" do
      expect(PackageManagerDownloadWorker).to receive(:perform_async).once.with("PackageManager::NPM", watched_project1.name, any_args)
      expect(PackageManagerDownloadWorker).to receive(:perform_async).once.with("PackageManager::Maven::MavenCentral", watched_project2.name, any_args)
      expect(PackageManagerDownloadWorker).not_to receive(:perform_async).with(String, unwatched_project.name, any_args)

      expect(CheckStatusWorker).to receive(:perform_async).once.with(watched_project1.id)
      expect(CheckStatusWorker).to receive(:perform_async).once.with(watched_project2.id)
      expect(CheckStatusWorker).not_to receive(:perform_async).with(unwatched_project.id)

      described_class.new.perform
    end
  end
end
