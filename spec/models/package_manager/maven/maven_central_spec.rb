# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Maven::MavenCentral do
  describe ".update" do
    context "with existing package with removed releases" do
      # several vulnerable releases of com.appdynamics:lambda-tracer were removed
      # from Maven Central: https://issues.sonatype.org/browse/OSSRH-49704
      let(:project_name) { "com.appdynamics:lambda-tracer" }
      let(:project) { Project.create(platform: "Maven", name: project_name) }

      # a version that was removed on Maven Central that we still know about
      let!(:remotely_removed_version) { project.versions.create(number: "1.0.2-1361", status: nil) }

      # a version that, as of October 2023, was still available on Maven Central
      let!(:existing_version) { project.versions.create(number: "1.1.1363", status: nil) }

      it "marks the remotely removed version as Removed" do
        VCR.use_cassette("maven-central/lambda-tracer") do
          described_class.update(project_name, sync_version: :all)
        end

        remotely_removed_version.reload
        existing_version.reload

        expect(remotely_removed_version.status).to eq("Removed")
        expect(existing_version.status).to eq(nil)
      end
    end
  end
end
