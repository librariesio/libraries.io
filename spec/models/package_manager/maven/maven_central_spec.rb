# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Maven::MavenCentral do
  describe ".latest_version_scraped" do
    context "when maven-metadata.xml's version contained an interpolation string" do
      let(:project_name) { "io.github.caffetteria:data-service-opencmis" }

      it "scrapes the maven HTML to find a real version" do
        latest_version_scraped = VCR.use_cassette("maven-central/data-service-opencmis") do
          described_class.latest_version_scraped(project_name)
        end

        expect(latest_version_scraped).to eq("1.1.1")
      end
    end
  end

  describe ".update" do
    context "with existing package with removed releases" do
      # several vulnerable releases of com.appdynamics:lambda-tracer were removed
      # from Maven Central: https://issues.sonatype.org/browse/OSSRH-49704
      let(:project_name) { "com.appdynamics:lambda-tracer" }
      let(:project) { Project.create(platform: "Maven", name: project_name) }

      # a version that was removed on Maven Central that we still know about
      let!(:remotely_removed_version) { project.versions.create(number: "1.0.2-1361", status: nil) }

      # a version that, as of November 2023, was still available on Maven Central
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

  describe ".versions_from_html" do
    it "retrieves versions from Maven Central index HTML" do
      VCR.use_cassette("maven-central/lambda-tracer") do
        # Matching versions as of November 2023
        expect(described_class.versions_from_html("com.appdynamics:lambda-tracer")).to match_array(%w[1.1.1363 1.2.1390 20.03.1391 20.11.1400])
      end
    end
  end
end
