# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Base::MissingVersionRemover do
  describe "#remove_missing_versions_of_project!" do
    let(:db_project) { Project.create(platform: "Pypi", name: project_name) }
    let(:project_name) { "name" }

    let(:version_to_keep_status) { nil }
    let!(:version_to_keep) { db_project.versions.create(number: "1.0.0", status: version_to_keep_status, updated_at: original_time) }

    let(:version_to_remove_status) { nil }
    let!(:version_to_remove) { db_project.versions.create(number: "2.0.0", status: version_to_remove_status, updated_at: original_time) }

    let(:version_already_removed_status) { "Removed" }
    let!(:version_already_removed) { db_project.versions.create(number: "3.0.0", status: version_already_removed_status, updated_at: original_time) }

    let(:version_in_another_state_status) { "Deprecated" }
    let!(:version_in_another_state) { db_project.versions.create(number: "4.0.0", status: version_in_another_state_status, updated_at: original_time) }

    let(:original_time) { Time.zone.parse("2010-01-01 10:00:00") }
    let(:removal_time) { Time.zone.parse("2020-01-01 10:00:00") }

    let(:versions_to_remove) { ["1.0.0"] }

    let(:remover) do
      described_class.new(
        project: db_project,
        version_numbers_to_keep: versions_to_remove,
        target_status: "Removed",
        removal_time: removal_time
      )
    end

    it "changes the missing releases to the indicated statuses" do
      remover.remove_missing_versions_of_project!

      version_to_keep.reload
      version_to_remove.reload
      version_already_removed.reload
      version_in_another_state.reload

      expect(version_to_keep.status).to eq(nil)
      expect(version_to_keep.updated_at).to eq(original_time)

      expect(version_to_remove.status).to eq("Removed")
      expect(version_to_remove.updated_at).to eq(removal_time)

      expect(version_already_removed.status).to eq("Removed")
      expect(version_already_removed.updated_at).to eq(original_time)

      expect(version_in_another_state.status).to eq("Removed")
      expect(version_in_another_state.updated_at).to eq(removal_time)
    end

    context "with no versions to remove" do
      let(:versions_to_remove) { ["1.0.0", "2.0.0", "3.0.0", "4.0.0"] }

      it "changes nothing" do
        remover.remove_missing_versions_of_project!

        version_to_keep.reload
        version_to_remove.reload
        version_already_removed.reload
        version_in_another_state.reload

        expect(version_to_keep.status).to eq(nil)
        expect(version_to_keep.updated_at).to eq(original_time)

        expect(version_to_remove.status).to eq(nil)
        expect(version_to_remove.updated_at).to eq(original_time)

        expect(version_already_removed.status).to eq("Removed")
        expect(version_already_removed.updated_at).to eq(original_time)

        expect(version_in_another_state.status).to eq("Deprecated")
        expect(version_in_another_state.updated_at).to eq(original_time)
      end
    end

    context "with all versions in target state" do
      let(:version_to_keep_status) { "Removed" }
      let(:version_to_remove_status) { "Removed" }
      let(:version_in_another_state_status) { "Removed" }

      it "changes nothing" do
        remover.remove_missing_versions_of_project!

        version_to_keep.reload
        version_to_remove.reload
        version_already_removed.reload
        version_in_another_state.reload

        expect(version_to_keep.status).to eq("Removed")
        expect(version_to_keep.updated_at).to eq(original_time)

        expect(version_to_remove.status).to eq("Removed")
        expect(version_to_remove.updated_at).to eq(original_time)

        expect(version_already_removed.status).to eq("Removed")
        expect(version_already_removed.updated_at).to eq(original_time)

        expect(version_in_another_state.status).to eq("Removed")
        expect(version_in_another_state.updated_at).to eq(original_time)
      end
    end
  end
end
