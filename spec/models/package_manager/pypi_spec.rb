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
      expect(PackageManager::Pypi).to receive(:project).with("foo").and_return({
                                                                                 "releases" => {
                                                                                   "0.0.1" => [{}],
                                                                                   "0.0.2" => [{ "yanked" => true, "yanked_reason" => "This package is deprecated" }],
                                                                                   "0.0.3" => [{}],
                                                                                 },
                                                                               })

      expect(described_class.deprecation_info("foo")).to eq({ is_deprecated: false, message: nil })
    end

    it "returns deprecated if last version is deprecated" do
      expect(PackageManager::Pypi).to receive(:project).with("foo").and_return({
                                                                                 "releases" => {
                                                                                   "0.0.1" => [{}],
                                                                                   "0.0.2" => [{ "yanked" => true, "yanked_reason" => "This package is deprecated" }],
                                                                                   "0.0.3" => [{ "yanked" => true, "yanked_reason" => "This package is deprecated" }],
                                                                                 },
                                                                               })

      expect(described_class.deprecation_info("foo")).to eq({ is_deprecated: true, message: "This package is deprecated" })
    end

    it "returns not-deprecated if last version is a pre-release and deprecated" do
      expect(PackageManager::Pypi).to receive(:project).with("foo").and_return({
                                                                                 "releases" => {
                                                                                   "0.0.1" => [{}],
                                                                                   "0.0.2" => [{}],
                                                                                   "0.0.3" => [{}],
                                                                                   "0.0.3a1" => [{ "yanked" => true, "yanked_reason" => "This package is deprecated" }],
                                                                                 },
                                                                               })

      expect(described_class.deprecation_info("foo")).to eq({ is_deprecated: false, message: nil })
    end

    it "return not-deprecated if 'development status' is not 'inactive'" do
      expect(PackageManager::Pypi).to receive(:project).with("foo").and_return({
                                                                                 "releases" => {},
                                                                                 "info" => {
                                                                                   "classifiers" => ["Development Status :: 5 - Production/Stable"],
                                                                                 },
                                                                               })

      expect(described_class.deprecation_info("foo")).to eq({ is_deprecated: false, message: nil })
    end

    it "return deprecated if 'development status' is 'inactive'" do
      expect(PackageManager::Pypi).to receive(:project).with("foo").and_return({
                                                                                 "releases" => {},
                                                                                 "info" => {
                                                                                   "classifiers" => ["Development Status :: 7 - Inactive"],
                                                                                 },
                                                                               })

      expect(described_class.deprecation_info("foo")).to eq({ is_deprecated: true, message: "Development Status :: 7 - Inactive" })
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
            ["PySocks", "(!=1.5.7,>=1.5.6) ; extra == 'socks'"],
            ["chardet", "(<6,>=3.0.2) ; extra == 'use_chardet_on_py3'"],
          ].map do |name, requirements|
            {
              project_name: name,
              requirements: requirements,
              kind: "runtime",
              optional: false,
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
end
