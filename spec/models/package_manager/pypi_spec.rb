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
        "python_version < \"3.10\" or extra == 'socks'",
      ],
      # URL dependency specifications are not supported by our current code so results in requirements which are not
      # usable.
      ["name@http://foo.com", "name", "@http://foo.com", ""],
      [
        "name [fred,bar] @ http://foo.com ; python_version=='2.7'",
        "name[fred,bar]",
        "@ http://foo.com",
        "python_version=='2.7'",
      ],
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

      before { version.set_dependencies_count }

      it "overwrites dependencies with force flag on" do
        expect(version.dependencies.count).to be 1

        VCR.use_cassette("pypi_dependencies_requests") do
          described_class.save_dependencies(mapped_project, sync_version: version_number, force_sync_dependencies: true)
        end

        expect { dependency.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect(version.dependencies.count).to be 6
      end

      it "updates the dependencies counters" do
        expect(version.dependencies.count).to be 1

        expect do
          VCR.use_cassette("pypi_dependencies_requests") do
            described_class.save_dependencies(mapped_project, sync_version: version_number, force_sync_dependencies: true)
          end
        end
          .to change { version.reload.dependencies_count }.to(6)
          .and change { version.runtime_dependencies_count }.to(4)
          .and change { SetProjectDependentsCountWorker.jobs.size }.by(1)
      end

      it "updates the dependencies counters when there are zero deps" do
        expect(PackageManager::Pypi).to receive(:dependencies).and_return([])
        expect do
          described_class.save_dependencies(mapped_project, sync_version: version_number, force_sync_dependencies: true)
        end
          .to change { version.reload.dependencies_count }.to(0)
          .and change { version.runtime_dependencies_count }.to(0)
      end

      it "leaves dependencies with force flag off" do
        expect(version.dependencies.count).to be 1

        VCR.use_cassette("pypi_dependencies_requests") do
          described_class.save_dependencies(mapped_project, sync_version: version_number, force_sync_dependencies: false)
        end

        expect(version.dependencies.count).to be 1
        expect(version.dependencies.first).to eql(dependency)
      end

      it "raises an error if the dependency info is invalid" do
        expect(PackageManager::Pypi).to receive(:dependencies).and_return([{ project_name: nil, requirements: nil }])
        expect do
          described_class.save_dependencies(mapped_project, sync_version: version_number, force_sync_dependencies: true)
        end.to raise_error(ActiveRecord::RecordInvalid)
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
            version_number: "#{version_number}.1",
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

  describe ".canonical_pypi_name?" do
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
        expect(described_class.canonical_pypi_name?(name)).to eq(true)
      end
    end

    context "with not present" do
      let(:present) { false }

      it "returns false" do
        expect(described_class.canonical_pypi_name?(name)).to eq(false)
      end
    end

    context "with non-matching name" do
      let(:api_project_name) { "PROJECT" }

      it "returns false" do
        expect(described_class.canonical_pypi_name?(name)).to eq(false)
      end
    end
  end

  describe ".update" do
    let(:project_name) { "package_name" }
    let(:project_license) { "MIT" }
    let(:project_summary) { "package summary" }
    let(:project_source_repository_url) { "https://www.libraries.io/package_name/source" }
    let(:removed_version) { "1.0.0" }
    let(:removed_version_published_at) { 1.year.ago.round }
    let(:not_removed_version) { "2.0.0" }
    let(:not_removed_version_published_at) { 1.week.ago.round }

    let(:project) do
      PackageManager::Pypi::JsonApiProject.new(
        {
          "info" => {
            "name" => project_name,
            "license" => project_license,
            "summary" => project_summary,
            "home_page" => "https://www.libraries.io/package_name/home",
            "project_urls" => { "Source" => project_source_repository_url },
          },
          "releases" =>
            {
              removed_version => [{
                "upload_time" => removed_version_published_at.iso8601,
                "yanked" => true,
                "yanked_reason" => "some reason",
              }],
              not_removed_version => [{
                "upload_time" => not_removed_version_published_at.iso8601,
                "yanked" => false,
              }],
            },
        }
      )
    end

    before do
      allow(PackageManager::Pypi).to receive(:project).and_return(project)
      allow(PackageManager::ApiService).to receive(:request_json_with_headers).and_return({})
      allow(PackageManager::Pypi::RssApiReleases).to receive(:request).and_return(
        instance_double(
          PackageManager::Pypi::RssApiReleases,
          releases: []
        )
      )
    end

    it "adds the project" do
      expect { described_class.update(project_name) }.to change(Project, :count).from(0).to(1)

      actual_project = Project.first
      expect(actual_project.name).to eq(project_name)
      expect(actual_project.platform).to eq("Pypi")
      expect(actual_project.description).to eq(project_summary)
      expect(actual_project.repository_url).to eq(project_source_repository_url)
      expect(actual_project.licenses).to eq(project_license)
      expect(actual_project.homepage).to eq("https://www.libraries.io/package_name/home")
    end

    context "when project already exists" do
      let!(:db_project) { create(:project, platform: "Pypi", name: project_name, homepage: "https://my.project.homepage") }

      it "overwrites the homepage" do
        described_class.update(project_name)

        expect(db_project.reload.homepage).to eq("https://www.libraries.io/package_name/home")
      end

      it "overwrites the homepage even when upstream value is nil" do
        expect(project).to receive(:homepage).and_return(nil).exactly(2).times
        described_class.update(project_name)

        expect(db_project.reload.homepage).to eq(nil)
      end
    end

    it "adds the versions with correct statuses" do
      expect { described_class.update(project_name) }.to change(Version, :count).from(0).to(2)

      actual_versions = Project.first.versions
      expect(actual_versions.count).to eq(2)

      actual_removed_version = actual_versions.find_by(number: removed_version)
      expect(actual_removed_version.status).to eq("Removed")
      expect(actual_removed_version.published_at).to eq(removed_version_published_at)

      actual_not_removed_version = actual_versions.find_by(number: not_removed_version)
      expect(actual_not_removed_version.status).to be nil
      expect(actual_not_removed_version.published_at).to eq(not_removed_version_published_at)
    end

    context "when the project and version already exist" do
      let(:release_status) { nil }
      let(:removed_version_old_status) { nil }
      let(:not_removed_version_old_status) { nil }
      let(:old_time) { 5.years.ago.round }

      before do
        p = create(:project, :pypi, name: project_name)
        create(:version, project: p, number: removed_version, status: removed_version_old_status, created_at: old_time, updated_at: old_time)
        create(:version, project: p, number: not_removed_version, status: not_removed_version_old_status, created_at: old_time, updated_at: old_time)
      end

      context "when the existing statuses are nil" do
        it "does not create extra versions" do
          expect { described_class.update(project_name) }.to_not change(Version, :count)

          expect(Project.first.versions.count).to eq(2)
        end

        it "updates the version to be yanked with the new status" do
          described_class.update(project_name)

          actual_removed_version = Project.first.versions.find_by(number: removed_version)
          expect(actual_removed_version.status).to eq("Removed")
          expect(actual_removed_version.updated_at).to be_within(1.minute).of(Time.zone.now)
        end

        it "does not do anything to the version that is not yanked" do
          described_class.update(project_name)

          actual_not_removed_version = Project.first.versions.find_by(number: not_removed_version)
          expect(actual_not_removed_version.status).to be nil
          expect(actual_not_removed_version.updated_at).to eq(old_time)
        end
      end

      context "when the existing statuses are 'Removed'" do
        let(:removed_version_old_status) { "Removed" }
        let(:not_removed_version_old_status) { "Removed" }

        it "does not do anything to the version that is still yanked" do
          described_class.update(project_name)

          actual_removed_version = Project.first.versions.find_by(number: removed_version)
          expect(actual_removed_version.status).to eq("Removed")
          expect(actual_removed_version.updated_at).to eq(old_time)
        end

        it "updates the formerly yanked version to not 'Removed'" do
          described_class.update(project_name)

          actual_not_removed_version = Project.first.versions.find_by(number: not_removed_version)
          expect(actual_not_removed_version.status).to be nil
          expect(actual_not_removed_version.updated_at).to be_within(1.minute).of(Time.zone.now)
        end
      end

      context "when the existing status are something else" do
        let(:removed_version_old_status) { "Deprecated" }
        let(:not_removed_version_old_status) { "Deprecated" }

        it "updates the 'Deprecated' version to 'Removed'" do
          described_class.update(project_name)

          actual_removed_version = Project.first.versions.find_by(number: removed_version)
          expect(actual_removed_version.status).to eq("Removed")
          expect(actual_removed_version.updated_at).to be_within(1.minute).of(Time.zone.now)
        end

        it "does not do anything to the version that is not yanked" do
          described_class.update(project_name)

          actual_not_removed_version = Project.first.versions.find_by(number: not_removed_version)
          expect(actual_not_removed_version.status).to eq("Deprecated")
          expect(actual_not_removed_version.updated_at).to eq(old_time)
        end
      end
    end
  end
end

describe PackageManager::Pypi::JsonApiProject do
  describe "#homepage_url" do
    context "when the homepage URL is returned in a different format" do
      let(:project_home_url) { "https://www.libraries.io/package_name/home" }
      let(:project) do
        PackageManager::Pypi::JsonApiProject.new(
          {
            "info" => {
              "project_urls" => { "Home" => project_home_url },
            },
          }
        )
      end

      it "returns the homepage URL" do
        expect(project.homepage).to be_present
      end
    end
  end
end
