# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Base::BulkVersionUpdater do
  describe "#run!" do
    let(:project) { create(:project) }

    let(:raw_versions) do
      %w[3.0.0 2.0.0 1.0.0].map.with_index do |v, idx|
        PackageManager::Base::ApiVersion.new(
          version_number: v,
          published_at: idx.days.ago,
          runtime_dependencies_count: 18,
          original_license: "MIT",
          repository_sources: nil,
          status: nil
        )
      end
    end

    let(:repository_source_name) { nil }
    let(:bulk_version_updater) { described_class.new(db_project: project, api_versions: api_versions_to_update, repository_source_name: repository_source_name) }

    context "with no version data" do
      let(:api_versions_to_update) { [] }

      it "no-ops" do
        expect { bulk_version_updater.run! }
          .to not_change { project.versions.count }
          .and not_change(project, :versions_count)
      end
    end

    context "with a single version" do
      let(:api_versions_to_update) { raw_versions[0, 1] }

      it "upserts a single version" do
        expect do
          bulk_version_updater.run!
        end.to change { project.versions.count }.by(1)
          .and change(project, :versions_count).to(1)

        version = project.versions.all.first
        expect(version.number).to eq("3.0.0")
        expect(version.original_license).to eq("MIT")
        expect(version.published_at).to_not be_nil
        expect(version.repository_sources).to be_nil
      end

      it "upserts a single version without recreating it" do
        bulk_version_updater.run!
        expect do
          bulk_version_updater.run!
        end.to not_change { project.versions.count }
          .and not_change(project, :versions_count)
      end
    end

    context "with three versions" do
      let(:api_versions_to_update) { raw_versions[0, 3] }

      it "upserts three versions" do
        expect do
          bulk_version_updater.run!
        end.to change { project.versions.count }.by(3)
          .and change(project, :versions_count).to(3)
        expect(project.versions.all.pluck("number")).to eq(["3.0.0", "2.0.0", "1.0.0"])
      end

      it "upserts three versions without recreating them" do
        bulk_version_updater.run!
        expect do
          bulk_version_updater.run!
        end.to not_change { project.versions.count }
          .and not_change(project, :versions_count)
      end
    end

    let(:repository_source_name) { nil }

    context "updating existing columns" do
      let(:api_versions_to_update) { raw_versions[0, 1] }
      let!(:version) { create(:version, project: project, number: api_versions_to_update[0].version_number) }

      it "should update published_at" do
        version.update_column(:published_at, 42.days.ago)
        bulk_version_updater.run!
        expect(version.reload.published_at).to be_within(1.second).of(1.day.ago)
      end

      it "should update updated_at" do
        version.update_column(:updated_at, 42.days.ago)
        bulk_version_updater.run!
        expect(version.reload.updated_at).to be_within(1.second).of(Time.now)
      end

      it "should update runtime_dependencies_count" do
        version.update_column(:runtime_dependencies_count, 3)
        bulk_version_updater.run!
        expect(version.reload.runtime_dependencies_count).to eq(18)
      end

      it "should update original_license" do
        version.update_column(:original_license, "FOO")
        bulk_version_updater.run!
        expect(version.reload.original_license).to eq("MIT")
      end

      it "should update status" do
        version.update_column(:status, "REMOVED")
        bulk_version_updater.run!
        expect(version.reload.status).to eq(nil)
      end

      {
        [["Main"], ["Main"]] => ["Main"],
        [["Main"], ["Maven"]] => %w[Main Maven],
        [nil, ["Maven"]] => ["Maven"],
        ["Main", nil] => ["Main"],
        [nil, nil] => nil,
      }.each_pair do |(original, new_value), expected|
        context "combining source_repositories of #{original.inspect} with #{new_value.inspect}" do
          let(:repository_source_name) { new_value }
          before { version.update_column(:repository_sources, original) }

          it "results in #{expected.inspect}" do
            bulk_version_updater.run!
            expect(version.reload.repository_sources).to eq(expected)
          end
        end
      end
    end

    context "with validations" do
      context "with missing version" do
        let(:api_versions_to_update) do
          [PackageManager::Base::ApiVersion.new(
            version_number: nil,
            published_at: 1.days.ago,
            runtime_dependencies_count: nil,
            original_license: "MIT",
            repository_sources: nil,
            status: nil
          )]
        end

        it "raises an error" do
          expect do
            bulk_version_updater.run!
          end
            .to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Number can't be blank")
            .and not_change(Version, :count)
        end
      end
    end

    context "running before_save" do
      let(:api_versions_to_update) { raw_versions[0, 3] }
      let(:version_numbers_called) { [] }

      it "runs update_spdx_expression on each version" do
        allow_any_instance_of(Version).to receive(:update_spdx_expression) { |v| version_numbers_called.push(v.number) }
        bulk_version_updater.run!

        expect(version_numbers_called).to eq(["3.0.0", "2.0.0", "1.0.0"])
      end
    end

    context "running after_create_commits" do
      context "when one of three versions already exists" do
        let(:api_versions_to_update) { raw_versions[0, 3] }
        before { create(:version, project: project, number: api_versions_to_update[0].version_number) }
        let(:version_numbers_called) { [] }

        it "runs send_notifications_async on only new versions" do
          allow_any_instance_of(Version).to receive(:send_notifications_async) { |v| version_numbers_called.push(v.number) }
          bulk_version_updater.run!

          expect(version_numbers_called).to eq(["2.0.0", "1.0.0"])
        end

        it "runs log_version_creation on only new versions" do
          allow_any_instance_of(Version).to receive(:log_version_creation) { |v| version_numbers_called.push(v.number) }
          bulk_version_updater.run!

          expect(version_numbers_called).to eq(["2.0.0", "1.0.0"])
        end

        # NOTE: that this callback affects the project without version context, so we only need to run it once for a batch of versions
        it "runs update_repository_async on only the first new version" do
          allow_any_instance_of(Version).to receive(:update_repository_async) { |v| version_numbers_called.push(v.number) }
          bulk_version_updater.run!

          expect(version_numbers_called).to eq(["2.0.0"])
        end

        # NOTE: that this callback affects the project without version context, so we only need to run it once for a batch of versions
        it "runs update_project_tags_async on only the first new version" do
          allow_any_instance_of(Version).to receive(:update_project_tags_async) { |v| version_numbers_called.push(v.number) }
          bulk_version_updater.run!

          expect(version_numbers_called).to eq(["2.0.0"])
        end
      end
    end
  end
end
