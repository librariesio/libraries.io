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

    context "latest version isn't deprecated" do
      let(:version_data) do
        {
          "0.0.1" => { "version" => "0.0.1", "deprecated" => "This package is deprecated" },
          "0.0.2" => { "version" => "0.0.2", "deprecated" => "This package is deprecated" },
          "0.0.3" => { "version" => "0.0.3" },
        }
      end

      it "project not considered deprecated" do
        expect(deprecation_info).to eq({ is_deprecated: false, message: nil })
      end
    end

    context "latest version isn't deprecated and the value of deprecated field is false" do
      let(:version_data) do
        {
          "0.0.1" => { "version" => "0.0.1", "deprecated" => "This package is deprecated" },
          "0.0.2" => { "version" => "0.0.2", "deprecated" => "This package is deprecated" },
          "0.0.3" => { "version" => "0.0.3", "deprecated" => false },
        }
      end

      it "project not considered deprecated" do
        expect(deprecation_info).to eq({ is_deprecated: false, message: nil })
      end
    end

    context "latest version is deprecated with a true boolean" do
      let(:version_data) do
        {
          "0.0.1" => { "version" => "0.0.1", "deprecated" => "This package is deprecated" },
          "0.0.2" => { "version" => "0.0.2", "deprecated" => "This package is deprecated" },
          "0.0.3" => { "version" => "0.0.3", "deprecated" => true },
        }
      end

      it "project is considered deprecated" do
        expect(deprecation_info).to eq({ is_deprecated: true, message: nil })
      end
    end

    context "latest version is a prerelease and deprecated" do
      let(:version_data) do
        {
          "0.0.1" => { "version" => "0.0.1" },
          "0.0.2" => { "version" => "0.0.2" },
          "0.0.3" => { "version" => "0.0.3-canary-release-01234", "deprecated" => "This release is a canary release" },
        }
      end

      it "project not considered deprecated" do
        expect(deprecation_info).to eq({ is_deprecated: false, message: nil })
      end
    end

    context "all versions deprecated" do
      let(:version_data) do
        {
          "0.0.1" => { "version" => "0.0.1", "deprecated" => "This package is deprecated" },
          "0.0.2" => { "version" => "0.0.2", "deprecated" => "This package is deprecated" },
          "0.0.3" => { "version" => "0.0.3", "deprecated" => "This package is deprecated" },
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
      described_class.remove_missing_versions(project, [PackageManager::Base::ApiVersion.new(
        version_number: "1.0.0",
        published_at: nil,
        original_license: nil,
        runtime_dependencies_count: nil,
        repository_sources: nil,
        status: nil
      )])
      expect(project.reload.versions.pluck(:number, :status)).to match_array([["1.0.0", nil], ["1.0.1", "Removed"]])
    end
  end

  describe ".mapping" do
    context "with an active project" do
      it "returns a mapping of raw data to our data" do
        raw_project = VCR.use_cassette("npm/eslint") do
          described_class.project("eslint")
        end
        mapped_project = described_class.mapping(raw_project)

        expect(mapped_project[:name]).to eq("eslint")
        expect(mapped_project[:description]).to eq("An AST-based pattern checker for JavaScript.")
        expect(mapped_project[:repository_url]).to eq("https://github.com/eslint/eslint")
        expect(mapped_project[:homepage]).to eq("https://eslint.org")
        expect(mapped_project[:keywords_array]).to eq(%w[ast lint javascript ecmascript espree])
        expect(mapped_project[:licenses]).to eq("MIT")
        expect(mapped_project[:versions].length).to eq(370)
      end
    end

    context "with an unpublished/Removed project" do
      it "returns a best-effort mapping of raw data to our data" do
        raw_project = {
          "_id" => "eslint-patch",
          "name" => "eslint-patch",
          "time" => {
            "created" => "2023-03-13T04:11:27.097Z",
            "8.0.11" => "2023-03-13T04:11:27.272Z",
            "modified" => "2023-03-15T02:57:26.602Z",
            "unpublished" => { "time" => "2023-03-15T02:57:26.602Z", "versions" => [] },
          },
        }
        mapped_project = described_class.mapping(raw_project)

        expect(mapped_project[:name]).to eq("eslint-patch")
        expect(mapped_project[:description]).to eq(nil)
        expect(mapped_project[:repository]).to eq(nil)
        expect(mapped_project[:homepage]).to eq(nil)
        expect(mapped_project[:keywords_array]).to eq([])
        expect(mapped_project[:licenses]).to eq("")
        expect(mapped_project[:versions].length).to eq(0)
      end
    end
  end

  describe ".dependencies" do
    context "when there are blank dependencies" do
      it "replaces blanks with '*' wildcards" do
        raw_project = VCR.use_cassette("npm/custodian") do
          described_class.project("custodian")
        end
        mapped_project = described_class.mapping(raw_project)
        dependencies = described_class.dependencies("custodian", "1.3.4", mapped_project)

        expect(dependencies.pluck(:project_name, :requirements)).to match_array([
          ["daemon", "1.1.0"],
          ["dateformat", "*"],
          ["nodemailer", "~0.3.28"],
          ["shell-quote", "0.0.1"],
        ])
      end
    end
  end
end
