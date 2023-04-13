# frozen_string_literal: true

require "rails_helper"

describe PackageManager::NuGet do
  let(:project) { create(:project, name: "foo", platform: described_class.formatted_name) }

  it 'has formatted name of "NuGet"' do
    expect(described_class.formatted_name).to eq("NuGet")
  end

  describe "#package_link" do
    it "returns a link to project website" do
      expect(described_class.package_link(project)).to eq("https://www.nuget.org/packages/foo/")
    end

    it "handles version" do
      expect(described_class.package_link(project, "2.0.0")).to eq("https://www.nuget.org/packages/foo/2.0.0")
    end
  end

  describe "download_url" do
    it "returns a link to project tarball" do
      expect(described_class.download_url(project, "1.0.0")).to eq("https://www.nuget.org/api/v2/package/foo/1.0.0")
    end
  end

  describe "#install_instructions" do
    it "returns a command to install the project" do
      expect(described_class.install_instructions(project)).to eq("Install-Package foo")
    end

    it "handles version" do
      expect(described_class.install_instructions(project, "2.0.0")).to eq("Install-Package foo -Version 2.0.0")
    end
  end

  describe "with release data" do
    def stub_releases(releases_data = {})
      allow(described_class)
        .to receive(:get_releases)
        .and_return(releases_data)
    end

    before do
      allow(described_class).to receive(:nuspec).and_return(nil)
    end

    # TODO: license urls are deprecated, but for now we'll fallback and include them as the license
    # if no other info is available. In the future, it probably makes sense to add a license url value
    # to a version so it's easier to work with by the consumer
    it "falls back to license url if license unavailable" do
      # Extremely abridged data
      stub_releases([
        "catalogEntry" => {
          "version" => "1.2.3",
          "licenseExpression" => "",
          "licenseUrl" => "http://some.url",
        },
      ])

      described_class.update(project.name)

      expect(Version.first.original_license).to eq "http://some.url"
    end
  end

  describe "with repo in nuspec data" do
    let(:repository_url) { "https://github.com/librariesio/libraries.io" }

    let(:nuspec_data) do
      Ox.parse(
        <<~XML
          <?xml version="1.0" encoding="utf-8"?>
          <package xmlns="http://schemas.microsoft.com/packaging/2013/05/nuspec.xsd">
            <metadata minClientVersion="2.12">
              <repository type="git" url="#{repository_url}" commit="bfd6048a605e9a0bebced7171a98bc3f04c78192" />
            </metadata>
          </package>
        XML
      )
    end

    let(:name) { "name" }
    let(:version) { "version" }

    let(:raw_project) do
      {
        name: name,
        releases: [
          {
            "catalogEntry" => {
              "version" => version,
            },
          },
        ],
      }
    end

    let(:result) { described_class.mapping(raw_project) }

    before do
      allow(described_class).to receive(:nuspec).with(name, version).and_return(nuspec_data)
    end

    it "uses repo data from nuspec" do
      expect(result[:repository_url]).to eq(repository_url)
    end
  end

  describe "deprecation_info" do
    let(:project) { Project.create(platform: "NuGet", name: name) }
    subject(:deprecation_info) do
      VCR.use_cassette(cassette) do
        described_class.deprecation_info(project)
      end
    end

    context "not deprecated upstream" do
      let(:name) { "Steeltoe.Common" }
      let(:cassette) { "nu_get/package" }

      it "is not deprecated" do
        expect(deprecation_info[:is_deprecated]).to eq(false)
        expect(deprecation_info[:message]).to be_blank
      end
    end

    context "deprecated upstream" do
      let(:name) { "Microsoft.DotNet.InternalAbstractions" }
      let(:cassette) { "nu_get/package_deprecated" }

      it "is deprecated" do
        expect(deprecation_info[:is_deprecated]).to eq(true)
        expect(deprecation_info[:message]).to be_present
      end
    end

    context "unlisted upstream" do
      let(:name) { "reactiveui-blend" }
      let(:cassette) { "nu_get/package_unlisted" }

      it "is deprecated" do
        expect(deprecation_info[:is_deprecated]).to eq(true)
        expect(deprecation_info[:message]).to include("unlisted")
      end
    end
  end

  describe ".nuspec" do
    let(:zip_file) { nil }
    let(:nuspec) { "" }
    let(:name) { "name" }
    let(:version) { "version" }

    let(:result) { described_class.nuspec(name, version) }

    before do
      allow(described_class).to receive(:package_file).with(name, version).and_return(zip_file)
    end

    context "bad zip file" do
      let(:zip_file) do
        StringIO.new("not a zip file")
      end

      it "returns nil" do
        expect(result).to eq(nil)
      end
    end

    context "good zip file" do
      let(:entry_name) { nil }
      let(:entry_content) { nil }

      let(:zip_file) do
        Zip::OutputStream.write_buffer do |new_zip|
          new_zip.put_next_entry(entry_name)
          new_zip.print entry_content
        end
      end

      context "no nuspec" do
        let(:entry_name) { "cats" }
        let(:entry_content) { "cats" }

        it "returns nil" do
          expect(result).to eq(nil)
        end
      end

      context "nuspec" do
        let(:entry_name) { "#{name.upcase}.nuspec" }

        context "not xml" do
          let(:entry_content) { "<xml" }

          it "returns nil" do
            expect(result).to eq(nil)
          end
        end

        context "xml" do
          let(:entry_content) { "<xml><cat /></xml>" }

          it "returns xml" do
            expect(result).to eq(Ox.parse(entry_content))
          end
        end
      end
    end
  end
end
