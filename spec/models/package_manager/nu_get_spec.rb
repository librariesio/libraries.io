# frozen_string_literal: true

require "rails_helper"

describe PackageManager::NuGet do
  before { freeze_time }

  let(:project) { create(:project, name: "foo", platform: described_class.formatted_name) }

  it 'has formatted name of "NuGet"' do
    expect(described_class.formatted_name).to eq("NuGet")
  end

  it 'has escaped name of "SömePackage"' do
    expect(described_class.escaped_name("SömePackage")).to eq("S%C3%B6mePackage")
  end

  it 'has unescaped name of "SömePackage"' do
    expect(described_class.unescaped_name("S%C3%B6mePackage")).to eq("SömePackage")
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
        raw_versions: [
          PackageManager::NuGet::SemverRegistrationProjectRelease.new(
            published_at: Time.now,
            version_number: version,
            project_url: "project_url",
            deprecation: nil,
            description: "description",
            summary: "summary",
            tags: [],
            licenses: "licenses",
            license_url: "license_url",
            dependencies: []
          ),
        ],
        versions: {
          number: version,
          published_at: Time.now,
          original_license: "licenses",
        },
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

    context "deprecated upstream with alternative" do
      let(:name) { "NuGet.Protocol.Core.v3" }
      let(:cassette) { "nu_get/package_deprecated_with_alternative" }

      it "is deprecated" do
        expect(deprecation_info[:is_deprecated]).to eq(true)
        expect(deprecation_info[:message]).to include("Legacy")
        expect(deprecation_info[:alternate_package]).to eq("NuGet.Protocol")
      end
    end

    context "deprecated upstream with message" do
      let(:name) { "Microsoft.DotNet.InternalAbstractions" }
      let(:cassette) { "nu_get/package_deprecated_with_message" }

      it "is deprecated" do
        expect(deprecation_info[:is_deprecated]).to eq(true)
        expect(deprecation_info[:message]).to include(".NET Package Deprecation effort")
      end
    end

    context "unlisted upstream" do
      let(:name) { "reactiveui-blend" }
      let(:cassette) { "nu_get/package_unlisted" }

      it "is deprecated" do
        expect(deprecation_info[:is_deprecated]).to eq(false)
        expect(deprecation_info[:message]).to be_blank
      end
    end

    context "first release deprecated, last not deprecated" do
      let(:name) { "NLog.Extensions.Logging" }
      let(:cassette) { "nu_get/deprecation_info/nlog_extensions_logging" }

      it "is not deprecated" do
        expect(deprecation_info[:is_deprecated]).to eq(false)
        expect(deprecation_info[:message]).to be_blank
      end
    end

    context "no releases" do
      let(:name) { "Steeltoe.Common" }
      let(:cassette) { "nu_get/package" }

      before { allow(described_class).to receive(:raw_versions).and_return([]) }

      it "is not deprecated" do
        expect(deprecation_info[:is_deprecated]).to eq(false)
        expect(deprecation_info[:message]).to be_blank
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

      context "nuspec with non-ASCII name" do
        let(:name) { "SömePackage" }
        let(:entry_name) { "#{name.upcase}.nuspec" }

        context "xml" do
          let(:entry_content) { "<xml><cat /></xml>" }

          it "returns xml" do
            expect(result).to eq(Ox.parse(entry_content))
          end
        end
      end
    end
  end

  describe "::fetch_canonical_nuget_name" do
    subject(:result) do
      VCR.use_cassette(cassette) { described_class.fetch_canonical_nuget_name(name) }
    end
    let(:canonical_name) { "Newtonsoft.Json" }

    context "when input matches canonical" do
      let(:name) { canonical_name }
      let(:cassette) { "nu_get/canonical_name/canonical_name_match" }

      it "returns same name" do
        expect(result).to eq(name)
      end
    end

    context "when non-ASCII input matches canonical" do
      let(:canonical_name) { "Felsökning" }
      let(:name) { canonical_name }
      let(:cassette) { "nu_get/canonical_name/canonical_non_ascii_name_match" }

      it "returns same name" do
        expect(result).to eq(name)
      end
    end

    context "when name doesn't match" do
      let(:name) { "NewtonSoft.JSON" }
      let(:cassette) { "nu_get/canonical_name/canonical_name_nonmatch" }

      it "returns the one answer we can treat as canonical" do
        expect(result).not_to eq(name)
        expect(result).to eq("Newtonsoft.Json")
      end
    end

    context "without cassette" do
      subject(:result) do
        described_class.fetch_canonical_nuget_name(name)
      end
      let(:name) { "NewtonSoft.JSON" }

      before do
        allow(described_class).to receive(:get_html)
          .with("https://nuget.org/packages/#{name}")
          .and_return(stub_page)
      end

      context "when expected response" do
        let(:stub_page) do
          Nokogiri::HTML(
            <<~HTML
              <!DOCTYPE html>
              <html lang="en">
              <head>
                <meta charset="utf-8" />
                <meta property="og:url" content="https://nuget.org/packages/#{canonical_name}/" />
              <head>
              </html>
            HTML
          )
        end
      end

      context "when request failed" do
        let(:stub_page) { Nokogiri::HTML("") }

        it "logs instance and returns nil" do
          expect(StructuredLog).to receive(:capture).with("FETCH_CANONICAL_NAME_FAILED", { platform: "nuget", name: name })

          expect(result).to eq(nil)
        end
      end

      context "when element missing" do
        let(:stub_page) do
          Nokogiri::HTML(
            <<~HTML
              <!DOCTYPE html>
              <html lang="en">
              <head>
                <title>Whoops</title>
              <head>
              </html>
            HTML
          )
        end

        it "logs instance and returns false" do
          expect(StructuredLog).to receive(:capture).with("CANONICAL_NAME_ELEMENT_MISSING", { platform: "nuget", name: name })

          expect(result).to eq(false)
        end
      end

      context "when unexpected format" do
        let(:stub_page) do
          Nokogiri::HTML(
            <<~HTML
              <!DOCTYPE html>
              <html lang="en">
              <head>
                <meta charset="utf-8" />
                <meta property="og:url" content="https://coolpackages.nuget.org/packages/#{canonical_name}/" />
              <head>
              </html>
            HTML
          )
        end

        it "raises error" do
          expect { result }.to raise_error(described_class::ParseCanonicalNameFailedError)
        end
      end
    end
  end

  describe ".versions" do
    let(:name) { "name" }
    let(:version) { "version" }
    let(:raw_project) do
      {
        name: name,
        raw_versions: [
          PackageManager::NuGet::SemverRegistrationProjectRelease.new(
            published_at: Time.now,
            version_number: version,
            project_url: "project_url",
            deprecation: nil,
            description: "description",
            summary: "summary",
            tags: [],
            licenses: "licenses",
            license_url: "license_url",
            dependencies: []
          ),
        ],
        # Note that :versions is usually set in project() but we're not
        # setting it here yet to show that it returns the proper thing
      }
    end

    it "maps raw_versions to versions correctly" do
      versions = described_class.versions(raw_project, name)

      expect(versions).to eq([
        {
          number: "version",
          published_at: Time.now.iso8601,
          original_license: "licenses",
          status: nil,
        },
      ])
    end

    context "when it contains a deprecated release" do
      before do
        raw_project[:raw_versions] << PackageManager::NuGet::SemverRegistrationProjectRelease.new(
          published_at: DateTime.new(1900, 1, 1),
          version_number: "version2",
          project_url: "project_url",
          deprecation: PackageManager::NuGet::SemverRegistrationProjectDeprecation.new(
            message: "this release is deprecated, but the package is still fine",
            alternate_package: nil
          ),
          description: "description",
          summary: "summary",
          tags: [],
          licenses: "licenses",
          license_url: "license_url",
          dependencies: []
        )
      end

      it "sets deprecated status and doesn't modify published_at" do
        versions = described_class.versions(raw_project, name)

        expect(versions).to eq([
          {
            number: "version",
            published_at: Time.now.iso8601,
            original_license: "licenses",
            status: nil,
          },
          {
            number: "version2",
            original_license: "licenses",
            status: "Deprecated",
          },
        ])
      end
    end

    context "when it contains an unlisted release" do
      before do
        raw_project[:raw_versions] << PackageManager::NuGet::SemverRegistrationProjectRelease.new(
          published_at: DateTime.new(1900, 1, 1),
          version_number: "version2",
          project_url: "project_url",
          deprecation: nil,
          description: "description",
          summary: "summary",
          tags: [],
          licenses: "licenses",
          license_url: "license_url",
          dependencies: []
        )
      end

      it "sets deprecated status and doesn't modify published_at" do
        versions = described_class.versions(raw_project, name)

        expect(versions).to eq([
          {
            number: "version",
            published_at: Time.now.iso8601,
            original_license: "licenses",
            status: nil,
          },
          {
            number: "version2",
            original_license: "licenses",
            status: "Deprecated",
          },
        ])
      end
    end
  end

  describe ".update" do
    subject(:result) do
      VCR.use_cassette(cassette) { described_class.update(name) }
    end
    let(:canonical_name) { "Newtonsoft.Json" }

    context "when project with canonical name exists" do
      let!(:project) { create(:project, :nuget, name: canonical_name) }

      context "when name matches canonical" do
        let(:name) { canonical_name }
        let(:cassette) { "nu_get/update/canonical_name_match" }

        it "updates the canonically named project" do
          expect(StructuredLog).to_not receive(:capture).with("CANONICAL_NAME_DIFFERS", any_args)

          expect(result).to eq(project)
          expect(result.name).to eq(canonical_name)
        end
      end

      context "when name does not match canonical" do
        let(:name) { "NewtonSoft.JSON" }
        let(:cassette) { "nu_get/update/canonical_name_nonmatch" }

        it "logs occurrence and updates the canonically named project" do
          expect(StructuredLog).to receive(:capture).with("CANONICAL_NAME_DIFFERS", { platform: "nuget", name: name, canonical_name: canonical_name })

          expect(result).to eq(project)
          expect(result.name).to eq(canonical_name)
        end
      end
    end

    context "when no project with canonical name exists" do
      context "when name matches canonical" do
        let(:name) { canonical_name }
        let(:cassette) { "nu_get/update/canonical_name_match" }

        it "uses the canonical name to create project" do
          expect(StructuredLog).to_not receive(:capture).with("CANONICAL_NAME_DIFFERS", any_args)

          expect(result).to be_a(Project)
          expect(result.name).to eq(canonical_name)
        end
      end

      context "when name does not match canonical" do
        let(:name) { "NewtonSoft.JSON" }
        let(:cassette) { "nu_get/update/canonical_name_nonmatch" }

        it "logs occurrence and uses the canonical name to create project" do
          expect(StructuredLog).to receive(:capture).with("CANONICAL_NAME_DIFFERS", { platform: "nuget", name: name, canonical_name: canonical_name })

          expect(result).to be_a(Project)
          expect(result.name).to eq(canonical_name)
        end
      end
    end
  end
end
