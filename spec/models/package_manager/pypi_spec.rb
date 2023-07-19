# frozen_string_literal: true

require "rails_helper"

describe PackageManager::Pypi do
  let(:project) { create(:project, name: "foo", platform: described_class.formatted_name) }

  it 'has formatted name of "PyPI"' do
    expect(described_class.formatted_name).to eq("PyPI")
  end

  describe "#package_link" do
    it "returns a link to project website" do
      expect(described_class.package_link(project)).to eq("https://pypi.org/project/foo/")
    end

    it "handles version" do
      expect(described_class.package_link(project, "2.0.0")).to eq("https://pypi.org/project/foo/2.0.0/")
    end
  end

  describe "#install_instructions" do
    it "returns a command to install the project" do
      expect(described_class.install_instructions(project)).to eq("pip install foo")
    end

    it "handles version" do
      expect(described_class.install_instructions(project, "2.0.0")).to eq("pip install foo==2.0.0")
    end
  end

  describe "project_find_names" do
    it "suggests underscore version of name" do
      suggested_find_names = described_class.project_find_names("test-hyphen")
      expect(suggested_find_names).to include("test_hyphen", "test-hyphen")
    end

    it "suggests hyphen version of name" do
      suggested_find_names = described_class.project_find_names("test_underscore")
      expect(suggested_find_names).to include("test-underscore", "test_underscore")
    end
  end

  describe "#deprecation_info" do
    let(:json_api_project) do
      instance_double(
        PackageManager::Pypi::JsonApiProject,
        deprecated?: true,
        deprecation_message: "wow"
      )
    end

    before do
      allow(described_class).to receive(:project).with(project.name).and_return(json_api_project)
    end

    it "calls through to the json api project" do
      expect(described_class.deprecation_info(project)).to eq({ is_deprecated: true, message: "wow" })
    end
  end

  describe ".dependencies" do
    it "returns the dependencies of a particular version" do
      VCR.use_cassette("pypi_dependencies_requests") do
        expect(
          described_class.dependencies("requests", "2.28.2")
        ).to match_array(
          [
            ["charset-normalizer", "<4,>=2"],
            ["idna", "<4,>=2.5"],
            ["urllib3", "<1.27,>=1.21.1"],
            ["certifi", ">=2017.4.17"],
            ["PySocks", "!=1.5.7,>=1.5.6", "extra == 'socks'", true],
            ["chardet", "<6,>=3.0.2", "extra == 'use_chardet_on_py3'", true],
          ].map do |name, requirements, kind = "runtime", optional = false|
            {
              project_name: name,
              requirements: requirements,
              kind: kind,
              optional: optional,
              platform: "Pypi",
            }
          end
        )
      end
    end

    it "handles dependencies with multiple extra scopes" do
      VCR.use_cassette("pypi_dependencies_isort") do
        expect(
          described_class.dependencies("isort", "5.12.0")
        ).to match_array(
          [
            ["colorama", ">=0.4.3", "extra == \"colors\""],
            ["pip-api", "*", "extra == \"requirements-deprecated-finder\""],
            ["pip-shims", ">=0.5.2", "extra == \"pipfile-deprecated-finder\""],
            ["pipreqs", "*", "extra == \"pipfile-deprecated-finder\" or extra == \"requirements-deprecated-finder\""],
            ["requirementslib", "*", "extra == \"pipfile-deprecated-finder\""],
            ["setuptools", "*", "extra == \"plugins\""],
          ].map do |name, requirements, kind|
            {
              project_name: name,
              requirements: requirements,
              kind: kind,
              optional: true,
              platform: "Pypi",
            }
          end
        )
      end
    end

    # Copied from the tests of https://peps.python.org/pep-0508/#complete-grammar
    [
      ["A", "A", "", ""],
      ["A>=3", "A", ">=3", ""],
      ["A.B-C_D", "A.B-C_D", "", ""],
      ["aa", "aa", "", ""],
      ["name", "name", "", ""],
      ["name<=1", "name", "<=1", ""],
      ["name>=3", "name", ">=3", ""],
      ["name>=3,<2", "name", ">=3,<2", ""],
      [
        "name[quux, strange];python_version<'2.7' and platform_version=='2'",
        "name[quux,strange]",
        "",
        "python_version<'2.7' and platform_version=='2'",
      ],
      [
        "name; os_name=='a' or os_name=='b'",
        "name",
        "",
        "os_name=='a' or os_name=='b'",
      ],
      [
        "name; os_name=='a' and os_name=='b' or os_name=='c'",
        "name",
        "",
        "os_name=='a' and os_name=='b' or os_name=='c'",
      ],
      [
        "name; os_name=='a' and (os_name=='b' or os_name=='c')",
        "name",
        "",
        "os_name=='a' and (os_name=='b' or os_name=='c')",
      ],
      [
        "name; os_name=='a' or os_name=='b' and os_name=='c'",
        "name",
        "",
        "os_name=='a' or os_name=='b' and os_name=='c'",
      ],
      [
        "name; (os_name=='a' or os_name=='b') and os_name=='c'",
        "name",
        "",
        "(os_name=='a' or os_name=='b') and os_name=='c'",
      ],
      [
        "foo (<6,>=3.0.2); extra == 'use_chardet_on_py3'",
        "foo",
        "<6,>=3.0.2",
        "extra == 'use_chardet_on_py3'",
      ],
      [
        "bar (>=3.2,<4.0) ; extra == \"django\" or extra == 'channels'",
        "bar",
        ">=3.2,<4.0",
        "extra == \"django\" or extra == 'channels'",
      ],
      [
        "foo; extra == \"pipfile-deprecated-finder\" or extra == \"requirements-deprecated-finder\"",
        "foo",
        "",
        "extra == \"pipfile-deprecated-finder\" or extra == \"requirements-deprecated-finder\"",
      ],
      [
        "foo(>=12.0.0) ; extra == \"debug\" or extra == \"debug-server\" and os_name == \"nt\"",
        "foo",
        ">=12.0.0",
        "extra == \"debug\" or extra == \"debug-server\" and os_name == \"nt\"",
      ],
      [
        "bar; python_version < \"3.10\" or extra == 'socks'",
        "bar",
        "",
        "python_version < \"3.10\" or extra == 'socks'"
      ],
      # URL dependency specifications are not supported by our current code so results in requirements which are not
      # usable.
      ["name@http://foo.com", "name", "@http://foo.com", ""],
      [
        "name [fred,bar] @ http://foo.com ; python_version=='2.7'",
        "name[fred,bar]",
        "@ http://foo.com",
        "python_version=='2.7'",
      ]
    ].each do |test, expected_name, expected_version, expected_environment_markers|
      it "#{test} should be parsed correctly" do
        expect(
          PackageManager::Pypi.parse_pep_508_dep_spec(test)
        ).to eq([expected_name, expected_version, expected_environment_markers])
      end
    end
  end

  describe "#save_dependencies" do
    context "with version dependencies" do
      let(:project) { create(:project, platform: "Pypi", name: "requests") }
      let!(:version) { create(:version, project: project, number: version_number) }
      let!(:dependency) { create(:dependency, version: version, project: project, platform: "Pypi", project_name: "my_bad_dep", requirements: "lol") }
      let(:version_number) { "2.28.2" }

      let(:mapped_project) do
        {
          name: project.name,
        }
      end

      it "overwrites dependencies with force flag on" do
        expect(version.dependencies.count).to be 1

        VCR.use_cassette("pypi_dependencies_requests") do
          described_class.save_dependencies(mapped_project, sync_version: version_number, force_sync_dependencies: true)
        end

        expect { dependency.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect(version.dependencies.count).to be 6
      end

      it "leaves dependencies with force flag off" do
        expect(version.dependencies.count).to be 1

        VCR.use_cassette("pypi_dependencies_requests") do
          described_class.save_dependencies(mapped_project, sync_version: version_number, force_sync_dependencies: false)
        end

        expect(version.dependencies.count).to be 1
        expect(version.dependencies.first).to eql(dependency)
      end
    end
  end

  describe ".versions" do
    it "retrieves data for a package that uses both the JSON and RSS APIs" do
      VCR.use_cassette("pypi/versions/ply") do
        raw_project = described_class.project("ply")

        # This will be empty, which is why we need to use the RSS feed to get the
        # publish date.
        expect(raw_project.releases.find { |r| r.version_number == "1.6" }.published_at).to eq(nil)

        versions = described_class.versions(raw_project, "ply")

        # We will get the published date from the RSS feed
        version16 = versions.find { |v| v[:number] == "1.6" }
        expect(version16[:published_at]).not_to be_nil
      end
    end
  end

  describe ".one_version" do
    let(:json_api_project) do
      instance_double(
        PackageManager::Pypi::JsonApiProject,
        releases: releases,
        license: license
      )
    end

    let(:published_at) { Time.zone.now }
    let(:license) { "MIT" }
    let(:version_number) { "1.0.0" }

    let(:releases) do
      [
        instance_double(
          PackageManager::Pypi::JsonApiProjectRelease,
          version_number: version_number,
          published_at: published_at
        ),
      ]
    end

    context "with existing version" do
      it "retrieves version information" do
        expect(described_class.one_version(json_api_project, version_number)).to eq({
                                                                                      number: version_number,
                                                                                      published_at: published_at,
                                                                                      original_license: license,
                                                                                    })
      end
    end

    context "without existing version" do
      let(:releases) do
        [
          instance_double(
            PackageManager::Pypi::JsonApiProjectRelease,
            version_number: version_number + ".1",
            published_at: published_at
          ),
        ]
      end

      it "does not retrieve information" do
        expect(described_class.one_version(json_api_project, version_number)).to eq(nil)
      end
    end

    context "with no releases" do
      let(:releases) do
        []
      end

      it "does not retrieve information" do
        expect(described_class.one_version(json_api_project, version_number)).to eq(nil)
      end
    end
  end

  describe ".has_canonical_pypi_name?" do
    let(:json_api_project) do
      instance_double(
        PackageManager::Pypi::JsonApiProject,
        present?: present,
        name: api_project_name
      )
    end
    let(:present) { true }
    let(:api_project_name) { "project" }
    let(:name) { "project" }

    before do
      allow(described_class).to receive(:project).with(name).and_return(json_api_project)
    end

    context "with remote data and matching name" do
      it "returns true" do
        expect(described_class.has_canonical_pypi_name?(name)).to eq(true)
      end
    end

    context "with not present" do
      let(:present) { false }

      it "returns false" do
        expect(described_class.has_canonical_pypi_name?(name)).to eq(false)
      end
    end

    context "with non-matching name" do
      let(:api_project_name) { "PROJECT" }

      it "returns false" do
        expect(described_class.has_canonical_pypi_name?(name)).to eq(false)
      end
    end
  end
end
