# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Pypi::VersionProcessor do
  describe "#execute" do
    let(:version1_time) { 1.hour.ago }
    let(:version2_time) { 2.hours.ago }
    let(:version3_time) { 3.hours.ago }
    let(:version4_time) { 4.hours.ago }

    let(:project_name) { "project-name" }

    let(:project_releases) do
      PackageManager::Pypi::JsonApiProjectReleases.new([
        PackageManager::Pypi::JsonApiProjectRelease.new(version_number: "1.0.0", published_at: version1_time, is_yanked: false, yanked_reason: nil),
        PackageManager::Pypi::JsonApiProjectRelease.new(version_number: "2.0.0", published_at: version2_time, is_yanked: false, yanked_reason: nil),
        PackageManager::Pypi::JsonApiProjectRelease.new(version_number: "3.0.0", published_at: version3_time, is_yanked: true, yanked_reason: "accidentally published"),
        PackageManager::Pypi::JsonApiProjectRelease.new(version_number: "4.0.0", published_at: nil, is_yanked: false, yanked_reason: nil),
      ])
    end

    let(:known_versions) do
      {
        "1.0.0": { number: "1.0.0", published_at: version1_time, original_license: "version1" },
      }
    end

    let(:rss_api_releases) do
      [
        PackageManager::Pypi::RssApiRelease.new(version_number: "3.0.0", published_at: version3_time),
        PackageManager::Pypi::RssApiRelease.new(version_number: "4.0.0", published_at: version4_time),
      ]
    end

    let(:json_api_release_requests) do
      {
        "1.0.0" => PackageManager::Pypi::JsonApiSingleRelease.new(data: { "info" => { "license" => "one" } }),
        "2.0.0" => PackageManager::Pypi::JsonApiSingleRelease.new(data: { "info" => { "license" => "two" } }),
        "3.0.0" => PackageManager::Pypi::JsonApiSingleRelease.new(data: { "info" => { "license" => "three" } }),
        "4.0.0" => PackageManager::Pypi::JsonApiSingleRelease.new(data: { "info" => { "license" => "four" } }),
      }
    end

    let(:version_processor) do
      described_class.new(
        known_versions: known_versions,
        project_name: project_name,
        project_releases: project_releases
      )
    end

    before do
      json_api_release_requests.each do |version, single_release|
        allow(version_processor).to receive(:json_api_single_release_for_version).with(version).and_return(single_release)
      end

      allow(version_processor).to receive(:rss_api_releases).and_return(rss_api_releases)
    end

    it "constructs the correct results" do
      results = version_processor.execute

      expect(results).to eq([
      { number: "1.0.0", published_at: version1_time, original_license: "one", yanked: false },
      { number: "2.0.0", published_at: version2_time, original_license: "two", yanked: false },
      { number: "3.0.0", published_at: version3_time, original_license: "three", yanked: true },
      { number: "4.0.0", published_at: version4_time, original_license: "four", yanked: false },
      ])
    end
  end
end
