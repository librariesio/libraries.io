# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Maven::Google do
  describe ".update" do
    # This is the method called by PackageManagerDownloadWorker.
    it "updates the package's version" do
      VCR.use_cassette("google-maven/memory-advice", match_requests_on: %i[method uri body query]) do
        described_class.update(
          "com.google.android.games:memory-advice",
          sync_version: "0.22"
        )
      end

      expect(Project.count).to eq(1)
      project = Project.first

      expect(project.name).to eq("com.google.android.games:memory-advice")
      expect(project.description).to eq("An experimental library to help applications avoid exceeding safe limits of memory use on devices.")
      expect(project.versions_count).to eq(1)

      expect(project.versions.first.number).to eq("0.22")
    end
  end

  describe ".dependencies" do
    before do
      allow(described_class).to receive(:parse_pom_manifest).and_return(
        [Bibliothecary::Dependency.new(name: "bibliothecary", requirement: "*", type: "runtime")]
      )
    end

    it "formats a dependency correctly" do
      result = described_class.dependencies(
        "name",
        "version",
        {}
      )

      expect(result).to eq([
        project_name: "bibliothecary",
        requirements: "*",
        kind: "runtime",
        optional: false,
        platform: "Maven",
      ])
    end
  end

  describe ".latest_version" do
    it "retrieves latest version from Google maven-metadata.xml" do
      VCR.use_cassette("google-maven/memory-advice") do
        # Matching latest version as of November 2023
        expect(described_class.latest_version("com.google.android.games:memory-advice")).to eq("0.24")
      end
    end
  end
end
