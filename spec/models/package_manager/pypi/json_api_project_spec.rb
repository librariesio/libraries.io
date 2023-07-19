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
      let(:raw_release) { [{ "upload_time" => time.iso8601 }] }

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
  end
end
