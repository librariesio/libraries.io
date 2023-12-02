# frozen_string_literal: true

require "rails_helper"

describe PackageManager::NPM do
  let(:project) { create(:project, name: "foo", platform: described_class.formatted_name) }

  it 'has formatted name of "npm"' do
    expect(described_class.formatted_name).to eq("npm")
  end

  describe "#package_link" do
    it "returns a link to project website" do
      expect(described_class.package_link(project)).to eq("https://www.npmjs.com/package/foo")
    end

    it "ignores version" do
      expect(described_class.package_link(project, "2.0.0")).to eq("https://www.npmjs.com/package/foo")
    end
  end

  describe "download_url" do
    it "returns a link to project tarball" do
      expect(described_class.download_url(project, "1.0.0")).to eq("https://registry.npmjs.org/foo/-/foo-1.0.0.tgz")
    end
  end

  describe "#install_instructions" do
    it "returns a command to install the project" do
      expect(described_class.install_instructions(project)).to eq("npm install foo")
    end

    it "handles version" do
      expect(described_class.install_instructions(project, "2.0.0")).to eq("npm install foo@2.0.0")
    end
  end

  describe "#deprecation_info" do
    subject(:deprecation_info) { described_class.deprecation_info(project) }
    before do
      expect(PackageManager::NPM).to receive(:project).with("foo").and_return({ "versions" => version_data })
    end

    context "any version isn't deprecated" do
      let(:version_data) do
        {
          "0.0.1" => { "deprecated" => "This package is deprecated" },
          "0.0.2" => { "deprecated" => "This package is deprecated" },
          "0.0.3" => {},
        }
      end

      it "project not considered deprecated" do
        expect(deprecation_info).to eq({ is_deprecated: false, message: nil })
      end
    end

    context "all versions deprecated" do
      let(:version_data) do
        {
          "0.0.1" => { "deprecated" => "This package is deprecated" },
          "0.0.2" => { "deprecated" => "This package is deprecated" },
          "0.0.3" => { "deprecated" => "This package is deprecated" },
        }
      end

      it "project considered deprecated" do
        expect(deprecation_info).to eq({ is_deprecated: true, message: "This package is deprecated" })
      end
    end

    context "no published versions" do
      let(:version_data) { {} }

      it "project not considered deprecated" do
        expect(deprecation_info).to eq({ is_deprecated: false, message: nil })
      end
    end
  end

  describe ".remove_missing_versions" do
    before do
      project.versions.create!(number: "1.0.0")
      project.versions.create!(number: "1.0.1")
    end

    it "should mark missing versions as Removed" do
      described_class.remove_missing_versions(project, ["1.0.0"])
      expect(project.reload.versions.pluck(:number, :status)).to match_array([["1.0.0", nil], ["1.0.1", "Removed"]])
    end
  end
end
