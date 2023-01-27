# frozen_string_literal: true

require "rails_helper"

describe "one_off rake tasks" do
  describe "backfill missing pypi version dependencies" do
    # let(:project) { create(:project, platform: "Pypi", name: "requests") }

    before do
      # Recreation of bug which was causing dependencies to blow up
      allow(PackageManager::Pypi).to receive(:dependencies).and_raise(StandardError)

      VCR.use_cassette("package_manager_download_worker_pypi_requests_2_28_2", record: :new_episodes) do
        PackageManagerDownloadWorker.new.perform("Pypi", "requests", "2.28.2")
      end

      expect(Project.count).to be(1)
      expect(Version.count).to be(1)
      expect(Version.first.dependencies.count).to be(0)

      # Restore working dependencies method
      allow(PackageManager::Pypi).to receive(:dependencies).and_call_original
    end

    it "Backfills the dependencies" do
      expect(Version.first.dependencies.count).to be(0)
      expect do
        VCR.use_cassette("package_manager_download_worker_pypi_requests_2_28_2") do
          Rake::Task["one_off:backfill_pypi_version_dependencies"].execute(limit: 1)
        end
      end.to change { Version.first.runtime_dependencies_count }
        .from(nil).to(6)
      expect(Version.first.dependencies.count).to be(6)
    end

    context "with already backfilled dependencies" do
      before do
        Version.first.update!(runtime_dependencies_count: 1)
      end

      it "Doesn't make any changes" do
        expect do
          VCR.use_cassette("package_manager_download_worker_pypi_requests_2_28_2") do
            Rake::Task["one_off:backfill_pypi_version_dependencies"].execute(limit: 1)
          end
        end.not_to change(Version.first.dependencies, :count)
      end
    end
  end
end
