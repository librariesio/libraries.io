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

  describe "finds repository urls" do
    it "from the rarely-populated repository url" do
      requests = JSON.parse(File.open("spec/fixtures/pypi-with-repository.json").read)
      expect(described_class.mapping(requests)[:repository_url]).to eq("https://github.com/python-attrs/attrs")
    end
  end

  describe "handles licenses" do
    it "from classifiers" do
      requests = JSON.parse(File.open("spec/fixtures/pypi-specified-license.json").read)
      expect(described_class.mapping(requests)[:licenses]).to eq("Apache 2.0")
    end

    it "from classifiers" do
      bandit = JSON.parse(File.open("spec/fixtures/pypi-classified-license-only.json").read)
      expect(described_class.mapping(bandit)[:licenses]).to eq("Apache Software License")
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
    it "returns not-deprecated if last version isn't deprecated" do
      expect(PackageManager::Pypi).to receive(:project).with("foo").and_return(
        {
          "releases" => {
            "0.0.1" => [{}],
            "0.0.2" => [{ "yanked" => true, "yanked_reason" => "This package is deprecated" }],
            "0.0.3" => [{}],
          },
        }
      )

      expect(described_class.deprecation_info(project)).to eq({ is_deprecated: false, message: nil })
    end

    it "returns deprecated if last version is deprecated" do
      expect(PackageManager::Pypi).to receive(:project).with("foo").and_return(
        {
          "releases" => {
            "0.0.1" => [{}],
            "0.0.2" => [{ "yanked" => true, "yanked_reason" => "This package is deprecated" }],
            "0.0.3" => [{ "yanked" => true, "yanked_reason" => "This package is deprecated" }],
          },
        }
      )

      expect(described_class.deprecation_info(project)).to eq({ is_deprecated: true, message: "This package is deprecated" })
    end

    it "returns not-deprecated if last version is a pre-release and deprecated" do
      expect(PackageManager::Pypi).to receive(:project).with("foo").and_return(
        {
          "releases" => {
            "0.0.1" => [{}],
            "0.0.2" => [{}],
            "0.0.3" => [{}],
            "0.0.3a1" => [{ "yanked" => true, "yanked_reason" => "This package is deprecated" }],
          },
        }
      )

      expect(described_class.deprecation_info(project)).to eq({ is_deprecated: false, message: nil })
    end

    it "return not-deprecated if 'development status' is not 'inactive'" do
      expect(PackageManager::Pypi).to receive(:project).with("foo").and_return(
        {
          "releases" => {},
          "info" => {
            "classifiers" => ["Development Status :: 5 - Production/Stable"],
          },
        }
      )

      expect(described_class.deprecation_info(project)).to eq({ is_deprecated: false, message: nil })
    end

    it "return deprecated if 'development status' is 'inactive'" do
      expect(PackageManager::Pypi).to receive(:project).with("foo").and_return(
        {
          "releases" => {},
          "info" => {
            "classifiers" => ["Development Status :: 7 - Inactive"],
          },
        }
      )

      expect(described_class.deprecation_info(project)).to eq({ is_deprecated: true, message: "Development Status :: 7 - Inactive" })
    end
  end

  describe ".dependencies" do
    it "returns the dependencies of a particular version" do
      VCR.use_cassette("pypi_dependencies_requests") do
        expect(
          described_class.dependencies("requests", "2.28.2")
        ).to match_array(
          [
            ["charset-normalizer", "(<4,>=2)"],
            ["idna", "(<4,>=2.5)"],
            ["urllib3", "(<1.27,>=1.21.1)"],
            ["certifi", "(>=2017.4.17)"],
            ["PySocks", "(!=1.5.7,>=1.5.6)", "extra == 'socks'", true],
            ["chardet", "(<6,>=3.0.2)", "extra == 'use_chardet_on_py3'", true],
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
            ["colorama", "(>=0.4.3)", "extra == \"colors\""],
            ["pip-api", "*", "extra == \"requirements-deprecated-finder\""],
            ["pip-shims", "(>=0.5.2)", "extra == \"pipfile-deprecated-finder\""],
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
      ["A", "A", ""],
      ["A>=3", "A", ">=3"],
      ["A.B-C_D", "A.B-C_D", ""],
      ["aa", "aa", ""],
      ["name", "name", ""],
      ["name<=1", "name", "<=1"],
      ["name>=3", "name", ">=3"],
      ["name>=3,<2", "name", ">=3,<2"],
      ["name@http://foo.com", "name", "@http://foo.com"],
      [
        "name [fred,bar] @ http://foo.com ; python_version=='2.7'",
        "name",
        "[fred,bar] @ http://foo.com ; python_version=='2.7'",
      ],
      [
        "name[quux, strange];python_version<'2.7' and platform_version=='2'",
        "name",
        "[quux, strange];python_version<'2.7' and platform_version=='2'",
      ],
      [
        "name; os_name=='a' or os_name=='b'",
        "name",
        "os_name=='a' or os_name=='b'",
      ],
      [
        "name; os_name=='a' and os_name=='b' or os_name=='c'",
        "name",
        "os_name=='a' and os_name=='b' or os_name=='c'",
      ],
      [
        "name; os_name=='a' and (os_name=='b' or os_name=='c')",
        "name",
        "os_name=='a' and (os_name=='b' or os_name=='c')",
      ],
      [
        "name; os_name=='a' or os_name=='b' and os_name=='c'",
        "name",
        "os_name=='a' or os_name=='b' and os_name=='c'",
      ],
      [
        "name; (os_name=='a' or os_name=='b') and os_name=='c'",
        "name",
        "(os_name=='a' or os_name=='b') and os_name=='c'",
      ],
    ].each do |test, expected_name, expected_requirement|
      it "#{test} should be parsed correctly" do
        expect(
          PackageManager::Pypi.parse_pep_508_dep_spec(test)
        ).to eq([expected_name, expected_requirement])
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

  describe ".select_repository_url" do
    let(:result) { described_class.select_repository_url(raw_project) }

    let(:raw_project) do
      {
        "info" => {
          "project_urls" => project_urls,
        },
      }
    end

    context "project_urls.Code" do
      let(:project_urls) do
        { "Code" => "wow" }
      end

      it "uses correct value" do
        expect(result).to eq("wow")
      end
    end

    context "both Source and Code" do
      let(:project_urls) do
        { "Source" => "cool", "Code" => "wow" }
      end

      it "uses correct value" do
        expect(result).to eq("cool")
      end
    end

    context "none" do
      let(:project_urls) do
        {}
      end

      it "returns nil" do
        expect(result).to eq(nil)
      end
    end
  end

  describe ".parse_environment_markers" do
    [
      [
        # no extras
        "(<4,>=2)",
        [
          "(<4,>=2)",
          nil,
        ],
      ],
      [
        # extra wrapped in single quotes
        "(<6,>=3.0.2); extra == 'use_chardet_on_py3'",
        [
          "(<6,>=3.0.2)",
          "extra == 'use_chardet_on_py3'",
        ],
      ],
      [
        # multiple extras, 1 wrapped in single quotes, 1 in escaped double quotes
        "(>=3.2,<4.0) ; extra == \"django\" or extra == 'channels'",
        [
          "(>=3.2,<4.0)",
          "extra == \"django\" or extra == 'channels'",
        ],
      ],
      [
        # no version range
        "extra == \"pipfile-deprecated-finder\" or extra == \"requirements-deprecated-finder\"",
        [
          nil,
          "extra == \"pipfile-deprecated-finder\" or extra == \"requirements-deprecated-finder\"",
        ],
      ],
      [
        # 2 extras and 1 other environment marker
        "(>=12.0.0) ; extra == \"debug\" or extra == \"debug-server\" and os_name == \"nt\"",
        [
          "(>=12.0.0)",
          "extra == \"debug\" or extra == \"debug-server\" and os_name == \"nt\"",
        ],
      ],
    ].each do |requirement, expected|
      it "parses the extras out of #{requirement} correctly" do
        expect(
          described_class.parse_environment_markers(requirement)
        ).to eq(expected)
      end
    end
  end
end
