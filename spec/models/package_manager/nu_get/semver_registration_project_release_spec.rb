# frozen_string_literal: true

require "rails_helper"

describe PackageManager::NuGet::SemverRegistrationProjectRelease do
  describe "#original_license" do
    let(:project_release) do
      described_class.new(
        published_at: Time.now,
        version_number: "version",
        project_url: "project_url",
        deprecation: nil,
        description: "description",
        summary: "summary",
        tags: [],
        licenses: licenses,
        license_url: license_url,
        dependencies: []
      )
    end

    let(:licenses) { "license" }
    let(:license_url) { "license url" }

    it "uses licenses over license url" do
      expect(project_release.original_license).to eq(licenses)
    end

    context "with only license url" do
      let(:licenses) { "" }
      it "uses license url" do
        expect(project_release.original_license).to eq(license_url)
      end
    end

    context "with only licenses" do
      let(:license_url) { "" }
      it "uses licenses" do
        expect(project_release.original_license).to eq(licenses)
      end
    end

    context "with neither" do
      let(:licenses) { "" }
      let(:license_url) { "" }
      it "uses neither" do
        expect(project_release.original_license).to eq(nil)
      end
    end
  end

  describe "#description" do
    let(:project_release) do
      described_class.new(
        published_at: Time.now,
        version_number: "version",
        project_url: "project_url",
        deprecation: nil,
        description: description,
        summary: summary,
        tags: [],
        licenses: "",
        license_url: "",
        dependencies: []
      )
    end

    let(:summary) { "summary" }
    let(:description) { "description" }

    context "with summary and description" do
      it "uses description over summary" do
        expect(project_release.description).to eq(description)
      end
    end

    context "with blank description" do
      let(:description) { "" }

      it "uses summary" do
        expect(project_release.description).to eq(summary)
      end
    end

    context "with blank summary" do
      let(:summary) { "" }

      it "uses description" do
        expect(project_release.description).to eq(description)
      end
    end
  end

  describe "#<=>" do
    let(:project_release_one_year) do
      described_class.new(
        published_at: 1.year.ago,
        version_number: "version",
        project_url: "project_url",
        deprecation: nil,
        description: "",
        summary: "",
        tags: [],
        licenses: "",
        license_url: "",
        dependencies: []
      )
    end

    let(:project_release_one_month) do
      described_class.new(
        published_at: 1.month.ago,
        version_number: "version",
        project_url: "project_url",
        deprecation: nil,
        description: "",
        summary: "",
        tags: [],
        licenses: "",
        license_url: "",
        dependencies: []
      )
    end

    let(:project_release_one_day) do
      described_class.new(
        published_at: 1.day.ago,
        version_number: "version",
        project_url: "project_url",
        deprecation: nil,
        description: "",
        summary: "",
        tags: [],
        licenses: "",
        license_url: "",
        dependencies: []
      )
    end

    it "sorts correctly" do
      expect([
        project_release_one_month, project_release_one_day, project_release_one_year
      ].sort).to eq([
          project_release_one_year, project_release_one_month, project_release_one_day
      ])
    end
  end
end
