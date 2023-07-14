require "rails_helper"

describe PackageManager::Pypi::JsonApiProject do
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
end
