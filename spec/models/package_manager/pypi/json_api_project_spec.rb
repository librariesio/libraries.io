# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Pypi::JsonApiProject do
  describe ".request" do
    let(:project_name) { "project" }
    let(:project_url) { "https://pypi.org/pypi/#{project_name}/json" }

    context "with error on retrieval" do
      before do
        allow(PackageManager::ApiService).to receive(:request_json_with_headers).with(project_url).and_raise(StandardError, "fail")
      end

      it "creates a new JsonApiProject with empty data" do
        response = described_class.request(project_name: project_name)

        expect(response.license).to eq(nil)
      end
    end

    context "with nil data" do
      before do
        allow(PackageManager::ApiService).to receive(:request_json_with_headers).with(project_url).and_return(nil)
      end

      it "creates a new JsonApiProject with empty data" do
        response = described_class.request(project_name: project_name)

        expect(response.license).to eq(nil)
      end
    end

    context "with data" do
      before do
        allow(PackageManager::ApiService).to receive(:request_json_with_headers).with(project_url).and_return({
                                                                                                                "info" => { "license" => "MIT" },
                                                                                                              })
      end

      it "creates a new JsonApiProject with data" do
        response = described_class.request(project_name: project_name)

        expect(response.license).to eq("MIT")
      end
    end
  end

  # These tests were migrated over from spec/models/package_manager/pypi_spec.rb
  # I'm keeping them as-is until we have a reason to update them.
  describe "#preferred_repository_url" do
    let(:requests) do
      JSON.parse(File.open("spec/fixtures/pypi-with-repository.json").read)
    end

    let(:project) { described_class.new(requests) }

    it "finds the rarely-populated repository url" do
      expect(project.preferred_repository_url).to eq("https://github.com/python-attrs/attrs")
    end
  end

  describe "handles licenses" do
    let(:project) { described_class.new(data) }

    context "with specified license" do
      let(:data) { JSON.parse(File.open("spec/fixtures/pypi-specified-license.json").read) }

      it "detects from specified license" do
        expect(project.licenses).to eq("Apache 2.0")
      end
    end

    context "with classified license only" do
      let(:data) { JSON.parse(File.open("spec/fixtures/pypi-classified-license-only.json").read) }

      it "detects from classifiers" do
        expect(project.licenses).to eq("Apache Software License")
      end
    end

    context "with nil classifiers" do
      let(:data) do
        {
          "info" => {},
        }
      end

      it "returns an empty string" do
        expect(project.licenses).to eq("")
      end
    end
  end

  describe "#repository_url" do
    let(:project) { described_class.new(raw_project) }

    let(:raw_project) do
      {
        "info" => {
          "project_urls" => project_urls,
        },
      }
    end

    context "with project_urls.Code" do
      let(:project_urls) do
        { "Code" => "wow" }
      end

      it "uses correct value" do
        expect(project.repository_url).to eq("wow")
      end
    end

    context "with both Source and Code" do
      let(:project_urls) do
        { "Source" => "cool", "Code" => "wow" }
      end

      it "uses correct value" do
        expect(project.repository_url).to eq("cool")
      end
    end

    context "with none" do
      let(:project_urls) do
        {}
      end

      it "returns nil" do
        expect(project.repository_url).to eq(nil)
      end
    end
  end

  describe "#deprecated? and #deprecation_message" do
    let(:releases) do
      [
        PackageManager::Pypi::JsonApiProjectRelease.new(version_number: "1.0.0-dev", is_yanked: dev_version_status[:yanked], yanked_reason: dev_version_status[:reason], published_at: nil),
        PackageManager::Pypi::JsonApiProjectRelease.new(version_number: "1.0.0", is_yanked: early_version_status[:yanked], yanked_reason: early_version_status[:reason], published_at: nil),
        PackageManager::Pypi::JsonApiProjectRelease.new(version_number: "2.0.0", is_yanked: latest_version_status[:yanked], yanked_reason: latest_version_status[:reason], published_at: nil),
      ]
    end
    let(:dev_version_status) { { yanked: false, reason: nil } }
    let(:early_version_status) { { yanked: false, reason: nil } }
    let(:latest_version_status) { { yanked: false, reason: nil } }

    let(:classifiers) { [] }

    let(:project) { described_class.new(data: nil) }

    before do
      allow(project).to receive(:releases).and_return(releases)
      allow(project).to receive(:classifiers).and_return(classifiers)
    end

    context "with latest stable yanked" do
      let(:latest_version_status) { { yanked: true, reason: "please don't use" } }

      it "#deprecated? returns false" do
        expect(project.deprecated?).to eq(false)
      end
    end

    context "with prerelease version yanked" do
      let(:dev_version_status) { { yanked: true, reason: "please don't use" } }

      it "#deprecated? returns false" do
        expect(project.deprecated?).to eq(false)
      end

      context "with latest stable yanked" do
        let(:latest_version_status) { { yanked: true, reason: "please don't use" } }

        it "#deprecated? returns false" do
          # should not deprecate as version 1.0.0 is not yanked
          expect(project.deprecated?).to eq(false)
        end
      end
    end

    context "with all non prerelease versions yanked" do
      let(:early_version_status) { { yanked: true, reason: "no" } }
      let(:latest_version_status) { { yanked: true, reason: "please don't use" } }

      it "#deprecated? returns true" do
        expect(project.deprecated?).to eq(true)
      end

      it "#deprecation_message returns value" do
        expect(project.deprecation_message).to eq(latest_version_status[:reason])
      end
    end

    context "with inactive classifier" do
      let(:classifiers) { [described_class::CLASSIFIER_INACTIVE] }

      it "#deprecated? returns true" do
        expect(project.deprecated?).to eq(true)
      end

      it "#deprecation_message returns classifier" do
        expect(project.deprecation_message).to eq(described_class::CLASSIFIER_INACTIVE)
      end
    end

    context "with no indicators" do
      it "#deprecated? returns false" do
        expect(project.deprecated?).to eq(false)
      end

      it "#deprecation_message returns nil" do
        expect(project.deprecation_message).to eq(nil)
      end
    end
  end

  describe "#releases" do
    let(:project) { described_class.new(raw_project) }
    let(:raw_project) do
      {
        "releases" => raw_releases,
      }
    end
    let(:raw_releases) { {} }

    context "with no releases" do
      it "returns nothing" do
        expect(project.releases).to be_empty
      end
    end

    context "with one release" do
      let(:raw_releases) { { "1.0.0" => raw_release } }
      let(:time) { Time.zone.now }
      let(:raw_release) do
        [{
          "upload_time" => time.iso8601,
          "yanked" => true,
          "yanked_reason" => "bad version",
        }]
      end

      it "parsed yanked" do
        expect(project.releases.first.yanked?).to eq(true)
      end

      it "parses yanked reason" do
        expect(project.releases.first.yanked_reason).to eq("bad version")
      end

      context "with empty yanked data" do
        let(:raw_release) do
          [{
            "upload_time" => time.iso8601,
            "yanked" => nil,
            "yanked_reason" => nil,
          }]
        end

        it "parsed yanked" do
          expect(project.releases.first.yanked?).to eq(false)
        end

        it "parses yanked reason" do
          expect(project.releases.first.yanked_reason).to eq(nil)
        end
      end

      context "with empty release" do
        let(:raw_release) { [] }

        it "returns a nil published_at" do
          expect(project.releases.count).to eq(1)

          release = project.releases.first

          expect(release.version_number).to eq("1.0.0")
          expect(release.published_at).to eq(nil)
        end
      end

      context "without upload time" do
        let(:raw_release) { [{}] }

        it "returns a nil published_at" do
          expect(project.releases.count).to eq(1)

          release = project.releases.first

          expect(release.version_number).to eq("1.0.0")
          expect(release.published_at).to eq(nil)
        end
      end

      context "with invalid upload time" do
        let(:raw_release) { [{ "upload_time" => "{]" }] }

        it "returns a nil published_at" do
          expect(project.releases.count).to eq(1)

          release = project.releases.first

          expect(release.version_number).to eq("1.0.0")
          expect(release.published_at).to eq(nil)
        end
      end

      context "with valid upload time" do
        it "returns the correct published_at" do
          expect(project.releases.count).to eq(1)

          release = project.releases.first

          expect(release.version_number).to eq("1.0.0")
          # deal with microtime
          expect(release.published_at).to be_within(1.second).of(time)
        end
      end
    end

    context "with three releases" do
      context "with point release older than highest stable release" do
        let(:raw_releases) do
          {
            "1.0.0" => [{
              "upload_time" => 1.day.ago.iso8601,
              "yanked" => false,
              "yanked_reason" => "",
            }],
            "1.0.1" => [{
              "upload_time" => 1.minute.ago.iso8601,
              "yanked" => false,
              "yanked_reason" => "",
            }],
            "2.0.0" => [{
              "upload_time" => 1.hour.ago.iso8601,
              "yanked" => true,
              "yanked_reason" => "use 1.0.1",
            }],
          }
        end

        it "orders releases chronologically" do
          expect(project.releases.count).to eq(3)
          expect(project.releases.map(&:version_number)).to eq(["1.0.0", "2.0.0", "1.0.1"])
        end
      end
    end
  end

  describe "#present?" do
    let(:json_api_project) { described_class.new(data) }
    let(:data) { { "info" => {} } }

    context "without data" do
      let(:data) { {} }

      it "returns false" do
        expect(json_api_project.present?).to eq(false)
      end
    end

    context "with data" do
      it "returns true" do
        expect(json_api_project.present?).to eq(true)
      end
    end
  end
end
