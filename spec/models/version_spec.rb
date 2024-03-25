# frozen_string_literal: true

require "rails_helper"

describe Version, type: :model do
  it { should belong_to(:project) }
  it { should have_many(:dependencies) }
  it { should have_many(:runtime_dependencies).conditions(kind: %w[runtime normal]) }

  it { should validate_presence_of(:project_id) }
  it { should validate_presence_of(:number) }

  context "spdx expressions" do
    let(:project) { create(:project) }
    it "updates spdx expressions on save" do
      version = Version.create(project: project, original_license: "MIT", number: "1.0.0")
      version.save
      expect(version.spdx_expression).to eq "MIT"
    end

    it "sets spdx expression to NONE when there is no license set" do
      version = Version.create(project: project, original_license: "", number: "1.0.0")
      version.save
      expect(version.spdx_expression).to eq "NONE"
    end

    it "sets spdx expression to NOASSERTION when the license is something we don't understand" do
      version = Version.create(project: project, original_license: "some fake license", number: "1.0.0")
      version.save
      expect(version.spdx_expression).to eq "NOASSERTION"
    end
  end

  context "with dependencies" do
    let(:version) { create(:version) }

    before do
      create(:dependency, version: version, requirements: "> 0", kind: "runtime")
      create(:dependency, version: version, requirements: "> 0", kind: "test")
    end

    it "can update its dependencies_count" do
      expect { version.set_dependencies_count }.to change { version.dependencies_count }.to(2)
    end

    it "can update its runtime_dependencies_count" do
      expect { version.set_runtime_dependencies_count }.to change { version.runtime_dependencies_count }.to(1)
    end
  end

  context ".bulk_after_create_commit" do
    let(:project) { create(:project) }
    let(:version1) { create(:version, number: "1.0.0", project: project) }
    let(:version2) { create(:version, number: "1.0.1", project: project) }
    let(:version3) { create(:version, number: "1.0.2", project: project) }
    let(:versions) { [version1, version2, version3] }

    it "calls send_notifications_async on each" do
      versions.each { |v| allow(v).to receive(:send_notifications_async) }

      Version.bulk_after_create_commit([version1, version2, version3], project)

      versions.each { |v| expect(v).to have_received(:send_notifications_async).once }
    end

    it "calls log_version_creation on each" do
      versions.each { |v| allow(v).to receive(:log_version_creation) }

      Version.bulk_after_create_commit([version1, version2, version3], project)

      versions.each { |v| expect(v).to have_received(:log_version_creation).once }
    end

    it "calls update_repository_async on first" do
      versions.each { |v| allow(v).to receive(:update_repository_async) }

      Version.bulk_after_create_commit([version1, version2, version3], project)

      expect(versions[0]).to have_received(:update_repository_async).once
      expect(versions[1]).to_not have_received(:update_repository_async)
      expect(versions[2]).to_not have_received(:update_repository_async)
    end

    it "calls update_project_tags_async on first" do
      versions.each { |v| allow(v).to receive(:update_project_tags_async) }

      Version.bulk_after_create_commit([version1, version2, version3], project)

      expect(versions[0]).to have_received(:update_project_tags_async).once
      expect(versions[1]).to_not have_received(:update_project_tags_async)
      expect(versions[2]).to_not have_received(:update_project_tags_async)
    end

    it "updates the project's versions_count" do
      project.update_column(:versions_count, 0)

      expect do
        Version.bulk_after_create_commit([version1, version2, version3], project)
      end.to change(project, :versions_count).to(3)
    end

    it "raises an error if any of the versions belong to a different project" do
      unrelated_version = create(:version)
      expect do
        Version.bulk_after_create_commit([version1, version2, version3, unrelated_version], project)
      end.to raise_error(/All records must be from the same project with id/)
    end
  end
end
