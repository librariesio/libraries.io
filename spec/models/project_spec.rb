# frozen_string_literal: true

require "rails_helper"

describe Project, type: :model do
  it { should have_many(:versions) }
  it { should belong_to(:latest_version) }
  it { should have_many(:dependencies) }
  it { should have_many(:contributions) }
  it { should have_many(:contributors) }
  it { should have_many(:tags) }
  it { should have_many(:dependents) }
  it { should have_many(:dependent_repositories) }
  it { should have_many(:subscriptions) }
  it { should have_many(:project_suggestions) }
  it { should have_one(:readme) }
  it { should belong_to(:repository) }
  it { should have_many(:repository_maintenance_stats) }
  it { should be_audited.only(%w[status name description repository_url homepage keywords_array licenses]) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:platform) }

  describe "#normalize_licenses" do
    let(:project) { create(:project, name: "foo", platform: PackageManager::Rubygems) }

    it "handles a single license" do
      project.licenses = "mit"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(["MIT"])
      expect(project.license_normalized).to be_truthy
    end

    it "handles comma separated license" do
      project.licenses = "mit,isc"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(%w[MIT ISC])
      expect(project.license_normalized).to be_truthy
    end

    it "handles OR separated licenses" do
      project.licenses = "mit OR isc"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(%w[MIT ISC])
      expect(project.license_normalized).to be_truthy
    end

    it "handles or separated licenses" do
      project.licenses = "mit or ISC"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(%w[MIT ISC])
      expect(project.license_normalized).to be_truthy
    end

    it "handles (OR) separated licenses" do
      project.licenses = "(mit OR isc)"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(%w[MIT ISC])
      expect(project.license_normalized).to be_truthy
    end

    it "handles (OR) separated licenses" do
      project.licenses = "(MIT or CC0-1.0)"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(["MIT", "CC0-1.0"])
      expect(project.license_normalized).to be_truthy
    end

    it "handles AND separated licenses" do
      project.licenses = "mit AND ISC"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(%w[MIT ISC])
      expect(project.license_normalized).to be_truthy
    end

    it "handles and separated licenses" do
      project.licenses = "mit and ISC"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(%w[MIT ISC])
      expect(project.license_normalized).to be_truthy
    end

    it "handles exact licenses" do
      project.licenses = "MIT"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(["MIT"])
      expect(project.license_normalized).to be_falsey
    end

    it "handles long licenses" do
      project.licenses = "x" * 200
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(["Other"])
      expect(project.license_normalized).to be_truthy
    end

    it "handles unknown licenses" do
      project.licenses = "Nonsense"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(["Other"])
      expect(project.license_normalized).to be_truthy
    end

    it "disables license normalization for licenses set by admin" do
      project.normalized_licenses = ["Apache-2.0"]
      project.license_set_by_admin = true
      project.licenses = "mit"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(["Apache-2.0"])
    end

    it "handles special case Apache License, Version 2.0" do
      project.licenses = "Apache License, Version 2.0"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(["Apache-2.0"])
      expect(project.license_normalized).to be_truthy
    end

    it "handles special case Apache Software License, Version 2.0" do
      project.licenses = "The Apache Software License, Version 2.0"
      project.normalize_licenses
      expect(project.normalized_licenses).to eq(["Apache-2.0"])
      expect(project.license_normalized).to be_truthy
    end
  end

  describe "#reformat_repository_url" do
    let!(:project) { create(:project) }

    it "should save the updated format URL" do
      project.update!(homepage: "https://libraries.io", repository_url: "scm:git:git://github.com/librariesio/libraries.io/libaries.io.git")
      project.reformat_repository_url

      expect(project.homepage).to eql "https://libraries.io"
      expect(project.repository_url).to eql "https://github.com/librariesio/libraries.io"
    end
  end

  describe "#update_repository" do
    context "with a repository_url that goes to a repository we have" do
      let(:full_name) { "librariesio/libraries.io" }
      let(:repository_url) { "https://github.com/#{full_name}" }
      let(:repository) { create(:repository, full_name: full_name) }
      let(:repository_url) { repository.url }
      let(:project) { create(:project, name: "foo", repository_url: repository_url) }

      before do
        allow(RepositoryHost::Github).to receive(:fetch_repo)
          .with(full_name, nil)
          .and_return(RepositoryHost::RawUpstreamData.new(full_name: full_name,
                                                          host_type: "github"))
      end

      it "sets project.repository to the existing repository" do
        expect(project.repository_id).to be_nil
        expect do
          project.update_repository
        end.not_to change(Repository, :count)
        expect(project.repository).to eq(repository)
      end

      context "with junk repository_url but a homepage url" do
        let(:project) { create(:project, name: "foo", repository_url: "junk", homepage: repository_url) }

        it "sets project.repository to the existing repository" do
          expect(project.repository_id).to be_nil
          expect do
            project.update_repository
          end.not_to change(Repository, :count)
          expect(project.repository).to eq(repository)
        end
      end

      context "with a repository url that goes to a different repository" do
        let(:different_full_name) { "foo/bar" }
        let(:different_repository_url) { "https://github.com/#{different_full_name}" }
        let(:project) { create(:project, name: "blah", repository_url: different_repository_url) }

        before do
          allow(RepositoryHost::Github).to receive(:fetch_repo)
            .with(different_full_name, nil)
            .and_return(RepositoryHost::RawUpstreamData.new(full_name: different_full_name,
                                                            host_type: "github"))
        end

        it "creates a new project.repository" do
          expect(project.repository_id).to be_nil
          expect do
            project.update_repository
          end.to change(Repository, :count).by(1)
          expect(project.repository).not_to eq(repository)
          expect(project.repository&.url).to eq(different_repository_url)
        end
      end
    end
  end

  describe ".find_best!" do
    context "with an exact match" do
      it "returns the record" do
        project = create(:project, name: "Django")
        expect(Project.find_best!(project.platform, project.name))
          .to eq(project)
      end
    end

    context "with a case-insensitive match" do
      it "returns the record" do
        project = create(:project, name: "Django")
        expect(Project.find_best!(project.platform, "django"))
          .to eq(project)
      end
    end

    context "with no match" do
      it "raises an error" do
        expect { Project.find_best!("unknown", "unknown") }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "querying a Pypi package based on PEP503 name normalization" do
      context "with underscores" do
        let!(:package) { create(:project, name: "test____underscores", platform: "Pypi") }

        it "finds the package by its normalized name" do
          expect(Project.find_best!("pypi", "test-underscores")).to eq(package)
        end

        it "finds the package by an equivalent un-normalized name" do
          expect(Project.find_best!("pypi", "test_-__underscores")).to eq(package)
        end
      end

      context "with dots" do
        let!(:package) { create(:project, name: "test.....dots", platform: "Pypi") }

        it "finds the package by its normalized name" do
          expect(Project.find_best!("pypi", "test-dots")).to eq(package)
        end

        it "finds the package by an equivalent un-normalized name" do
          expect(Project.find_best!("pypi", "test_-__..dots")).to eq(package)
        end
      end

      context "with hyphens" do
        let!(:package) { create(:project, name: "test-----hyphens", platform: "Pypi") }

        it "finds the package by its normalized name" do
          expect(Project.find_best!("pypi", "test-hyphens")).to eq(package)
        end

        it "finds the package by an equivalent un-normalized name" do
          expect(Project.find_best!("pypi", "test_-__..hyphens")).to eq(package)
        end
      end

      context "with a mix of hyphens, dots, underscores and uppercase" do
        let!(:package) { create(:project, name: "test---__a..mix--of-EVERYthing", platform: "Pypi") }

        it "finds the package by its normalized name" do
          expect(Project.find_best!("pypi", "test-a-mix-of-everything")).to eq(package)
        end

        it "finds the package by an equivalent un-normalized name" do
          expect(Project.find_best!("pypi", "test-__a..mix--of-everyTHING")).to eq(package)
        end
      end
    end
  end

  describe ".find_best" do
    context "with a match" do
      it "returns the record" do
        project = create(:project, name: "Django")
        expect(Project.find_best(project.platform, project.name))
          .to eq(project)
      end
    end

    context "with no match" do
      it "returns nil" do
        expect(Project.find_best("unknown", "unknown"))
          .to be_nil
      end
    end
  end

  describe ".find_all_with_package_manager!" do
    context "querying an NPM package" do
      let!(:package1) { create(:project, name: "some-npm-pkg", platform: "NPM") }
      let!(:package2) { create(:project, name: "another-npm-pkg", platform: "NPM") }

      it "finds a single package" do
        results = Project.find_all_with_package_manager!("npm", ["some-npm-pkg"])

        expect(results).to eq({
                                "some-npm-pkg" => package1,
                              })
      end

      it "finds multiple packages" do
        results = Project.find_all_with_package_manager!("npm", %w[some-npm-pkg another-npm-pkg])

        expect(results).to eq({
                                "some-npm-pkg" => package1,
                                "another-npm-pkg" => package2,
                              })
      end

      it "finds and doesn't find multiple packages" do
        results = Project.find_all_with_package_manager!("npm", %w[some-npm-pkg not-found-pkg])

        expect(results).to eq({
                                "some-npm-pkg" => package1,
                                "not-found-pkg" => nil,
                              })
      end
    end

    context "querying a Pypi package based on PEP503 name normalization" do
      let!(:package1) { create(:project, name: "test____underscores", platform: "Pypi") }
      let!(:package2) { create(:project, name: "test.....dots", platform: "Pypi") }
      let!(:package3) { create(:project, name: "test-----hyphens", platform: "Pypi") }
      let!(:package4) { create(:project, name: "test---__a..mix--of-EVERYthing", platform: "Pypi") }

      it "finds a single package" do
        results = Project.find_all_with_package_manager!("pypi", ["test-underscores"])

        expect(results).to eq({
                                "test-underscores" => package1,
                              })
      end

      it "finds multiple packages" do
        results = Project.find_all_with_package_manager!("pypi", %w[test-underscores test-dots test-hyphens test-a-mix-of-everything])

        expect(results).to eq({
                                "test-underscores" => package1,
                                "test-dots" => package2,
                                "test-hyphens" => package3,
                                "test-a-mix-of-everything" => package4,
                              })
      end

      it "finds and doesn't find multiple packages" do
        results = Project.find_all_with_package_manager!("pypi", %w[test-underscores test-not-found test-dots])

        expect(results).to eq({
                                "test-underscores" => package1,
                                "test-not-found" => nil,
                                "test-dots" => package2,
                              })
      end

      it "finds multiple package with different un-normalized names" do
        results = Project.find_all_with_package_manager!(
          "pypi",
          ["test__...--__underscores",
           "test....---__dots",
           "test....__---hyphens",
           "test____a....mix-of_-.everything"]
        )

        expect(results).to eq({
                                "test__...--__underscores" => package1,
                                "test....---__dots" => package2,
                                "test....__---hyphens" => package3,
                                "test____a....mix-of_-.everything" => package4,
                              })
      end
    end
  end

  describe "#async_sync" do
    let!(:project) { create(:project, platform: "NPM", name: "jade") }

    it "should kick off package manager download jobs" do
      expect { project.async_sync }.to change { PackageManagerDownloadWorker.jobs.size }.by(1)
    end

    it "should kick off status check job" do
      expect { project.async_sync }.to change { CheckStatusWorker.jobs.size }.by(1)
    end
  end

  describe "#check_status" do
    before { freeze_time }

    context "already checked recently" do
      let!(:project) { create(:project, platform: "NPM", name: "jade", status: "", status_checked_at: 12.hours.ago) }

      it "should not check status" do
        allow(Typhoeus).to receive(:get)

        expect { project.check_status }.to_not change(project, :status_checked_at)
        expect(Typhoeus).to_not have_received(:get)
      end
    end

    context "entire project deprecated with message" do
      let!(:project) { create(:project, platform: "NPM", name: "jade", status: "", updated_at: 1.week.ago) }

      it "should use the result of entire_package_deprecation_info" do
        VCR.use_cassette("project/check_status/jade") do
          project.check_status

          project.reload

          expect(project.status).to eq("Deprecated")
          expect(project.deprecation_reason).not_to eq(nil)
          expect(project.status_checked_at).to eq(DateTime.current)
          expect(project.updated_at).to eq(DateTime.current)
        end
      end
    end

    context "a go project missing from upstream" do
      let(:check_status_url) { PackageManager::Go.check_status_url(project) }

      context "recently created" do
        let!(:project) { create(:project, platform: "Go", name: "github.com/some-nonexistent-fake/pkg", status: nil, created_at: 1.hour.ago) }

        it "should not mark it as Removed for a 404" do
          WebMock.stub_request(:get, check_status_url).to_return(status: 404)

          project.check_status
          project.reload
          expect(project.status).to eq(nil)
          expect(project.status_checked_at).to eq(DateTime.current)
        end

        it "should not mark it as Removed for a 302" do
          WebMock.stub_request(:get, check_status_url).to_return(status: 302)

          project.check_status
          project.reload
          expect(project.status).to eq(nil)
          expect(project.status_checked_at).to eq(DateTime.current)
        end
      end

      context "not recently created" do
        let!(:project) { create(:project, platform: "Go", name: "github.com/some-nonexistent-fake/pkg", status: nil, created_at: 1.month.ago) }

        it "should mark it as Removed for a 404" do
          WebMock.stub_request(:get, check_status_url).to_return(status: 404)

          project.check_status
          project.reload
          expect(project.status).to eq("Removed")
          expect(project.status_checked_at).to eq(DateTime.current)
        end

        it "should mark it as Removed for a 302" do
          WebMock.stub_request(:get, check_status_url).to_return(status: 302)

          project.check_status
          project.reload
          expect(project.status).to eq("Removed")
          expect(project.status_checked_at).to eq(DateTime.current)
        end
      end
    end

    context "with response from NPM" do
      let!(:project) { create(:project, platform: "NPM", name: "coolpackage", status: nil, created_at: 1.month.ago) }
      let(:check_status_url) { PackageManager::NPM.check_status_url(project) }

      context "with a 429 response" do
        before { WebMock.stub_request(:get, check_status_url).to_return(status: 429, headers: { "retry-after" => 3 }) }

        it "raises an error and caches the 'retry-after' header in redis" do
          status_before = project.status

          expect { project.check_status }.to raise_error(Project::CheckStatusExternallyRateLimited)
          expect(project.reload.status).to eq(status_before)
        end
      end

      context "with a 200 response but unpublished" do
        it "raises an error and caches a fallback of 60 second retry-after in redis" do
          VCR.use_cassette("project/check_status/atguigu_english") do
            expect { project.check_status }.to change(project, :status).to("Removed")
          end
        end
      end

      context "with a 500 response" do
        before { WebMock.stub_request(:get, check_status_url).to_return(status: 500) }

        it "doesn't change the status" do
          status_before = project.status

          project.check_status
          project.reload
          expect(project.status).to eq(status_before)
        end
      end
    end

    context "some of project deprecated" do
      let!(:project) { create(:project, platform: "NPM", name: "react", status: nil, updated_at: 1.week.ago) }

      it "should use the result of entire_package_deprecation_info" do
        VCR.use_cassette("project/check_status/react") do
          project.check_status

          project.reload

          expect(project.status).to eq(nil)
          expect(project.audits.last.comment).to eq("Response 200")
          # Since there was no change, update status_checked_at but do not update updated_at
          expect(project.status_checked_at).to eq(DateTime.current)
          expect(project.updated_at).to eq(1.week.ago)
        end
      end
    end

    context "a private NPM package that returns 302" do
      let!(:project) { create(:project, platform: "NPM", name: "@abcdefgh/ijklmnop", status: nil, updated_at: 1.week.ago) }

      it "should mark it as Removed since it's not accessible" do
        VCR.use_cassette("project/check_status/private_package") do
          project.check_status

          project.reload

          expect(project.status).to eq("Removed")
          expect(project.audits.last.comment).to eq("Response 404")
          expect(project.status_checked_at).to eq(DateTime.current)
          expect(project.updated_at).to eq(DateTime.current)
        end
      end
    end

    context "deprecated project no longer deprecated" do
      let!(:project) { create(:project, platform: "NPM", name: "react", status: "Deprecated", updated_at: 1.week.ago) }

      it "should mark the project no longer deprecated" do
        VCR.use_cassette("project/check_status/react") do
          project.check_status

          project.reload

          expect(project.status).to eq(nil)
          expect(project.deprecation_reason).to eq(nil)
          expect(project.status_checked_at).to eq(DateTime.current)
          expect(project.updated_at).to eq(DateTime.current)
        end
      end
    end

    context "removed project no longer removed" do
      context "when package manager can have entire package deprecated" do
        let!(:project) { create(:project, platform: "NPM", name: "react", status: "Removed") }

        it "should mark the project no longer removed" do
          VCR.use_cassette("project/check_status/react") do
            project.check_status

            project.reload

            expect(project.status).to eq(nil)
          end
        end
      end

      context "when package manager cannot have entire package deprecated" do
        let!(:project) { create(:project, platform: "Rubygems", name: "rails", status: "Removed") }

        it "should mark the project no longer removed" do
          VCR.use_cassette("project/check_status/rails") do
            project.check_status

            project.reload

            expect(project.status).to eq(nil)
          end
        end
      end
    end

    context "a hidden project that is active" do
      let!(:project) { create(:project, :npm, name: "react", status: "Hidden") }

      it "should keep the project hidden" do
        VCR.use_cassette("project/check_status/react") do
          project.check_status

          project.reload

          expect(project.status).to eq("Hidden")
          expect(project.status_checked_at).to eq(DateTime.current)
          expect(project.updated_at).to eq(DateTime.current)
        end
      end
    end
  end

  describe "DeletedProject management" do
    let!(:project) { create(:project, platform: "NPM", name: "react") }

    it "should create a DeletedProject when destroyed" do
      expect(DeletedProject.count).to eq(0)
      digest = DeletedProject.digest_from_platform_and_name(project.platform, project.name)
      expect(digest).to eq("ef64ba66a6ca7f649a3e384bf2345e05698d6100b931fe14a21853a3af82900c")
      project.destroy!
      expect(DeletedProject.count).to eq(1)
      dp = DeletedProject.first
      expect(dp.digest).to eq(digest)
    end

    it "should remove a DeletedProject when resurrected" do
      expect(DeletedProject.count).to eq(0)
      digest = DeletedProject.digest_from_platform_and_name(project.platform, project.name)
      expect(digest).to eq("ef64ba66a6ca7f649a3e384bf2345e05698d6100b931fe14a21853a3af82900c")
      project.destroy!
      expect(DeletedProject.count).to eq(1)
      create(:project, platform: "NPM", name: "react")
      expect(DeletedProject.count).to eq(0)
    end
  end

  describe "#mailing_list" do
    let(:repository) { create(:repository) }
    let(:project) { create(:project, repository: repository) }

    def create_sub(user)
      Subscription.create(project: project, user: user)
    end

    def create_repo_sub(user)
      repo_sub = RepositorySubscription.create(user: user, repository: repository)
      Subscription.create(project: project, repository_subscription: repo_sub)
    end

    it "builds a version mailing list for notifications" do
      create_sub(create(:user))
      create_repo_sub(create(:user))
      expect(project.mailing_list.count).to eq 2
    end

    it "doesn't email users with disabled emails" do
      create_sub(create(:user))
      create_sub(create(:user, emails_enabled: false))

      expect(project.mailing_list.count).to eq 1
    end

    it "doesn't email users who muted project" do
      mute_user = create(:user)
      create_sub(mute_user)
      create_sub(create(:user))
      ProjectMute.create(project: project, user: mute_user)

      expect(project.mailing_list.count).to eq 1
    end
  end

  describe "#update_details" do
    let!(:project) { create(:project) }
    let!(:older_release) { create(:version, project: project, number: "1.0.0", published_at: 1.year.ago, id: 2000, created_at: 1.month.ago) }
    let!(:newer_release) { create(:version, project: project, number: "2.0.0", published_at: 1.month.ago, id: 1000, created_at: 1.year.ago) }

    context "when latest_version_id is out-of-date" do
      before { project.update_column(:latest_version_id, older_release.id) }

      it "should update latest_version_id" do
        expect { project.update_details }.to change { project.latest_version_id }.from(older_release.id).to(newer_release.id)
      end
    end
  end

  describe "#latest_release" do
    let!(:project) { create(:project) }
    let!(:newer_release) { create(:version, project: project, number: "2.0.0", published_at: 1.month.ago, id: 1000, created_at: 1.year.ago) }
    let!(:older_release) { create(:version, project: project, number: "1.0.0", published_at: 1.year.ago, id: 2000, created_at: 1.month.ago) }

    it "returns the newer release as latest" do
      expect(project.latest_release).to eql(newer_release)
    end

    context "with no publish dates" do
      before do
        newer_release.update!(published_at: nil)
        older_release.update!(published_at: nil)
        project.set_latest_version
      end

      it "returns the latest created release" do
        expect(project.latest_release).to eql(older_release)
      end
    end

    context "with nils mixed with publish dates" do
      before do
        older_release.update!(published_at: nil)
      end

      it "returns the latest created release" do
        expect(project.latest_release).to eql(newer_release)
      end
    end

    context "with all nil published dates" do
      before do
        older_release.update!(published_at: nil)
        newer_release.update!(published_at: nil)
        project.set_latest_version
      end

      it "returns the latest created release" do
        expect(project.latest_release).to eql(older_release)
      end
    end
  end

  describe "#manual_sync" do
    let!(:project) { create(:project, platform: "Rubygems", name: "my_gem") }

    before { allow(PackageManagerDownloadWorker).to receive(:perform_async) }

    it "sends option to sync all dependencies to download worker" do
      project.manual_sync

      expect(PackageManagerDownloadWorker).to have_received(:perform_async).with(
        "PackageManager::Rubygems",
        project.name,
        nil,
        "project",
        0,
        true
      )
    end
  end

  describe ".platform" do
    subject(:scoped_collection) { described_class.platform(given_platforms) }

    let!(:ruby1) { create(:project, :rubygems) }
    let!(:ruby2) { create(:project, :rubygems) }
    let!(:npm1) { create(:project, :npm) }

    context "mismatched case" do
      let(:given_platforms) { "RubyGems" }

      it "includes all matches" do
        expect(scoped_collection).to match_array([ruby1, ruby2])
      end
    end

    context "exact case" do
      let(:given_platforms) { "Rubygems" }

      it "includes all matches" do
        expect(scoped_collection).to match_array([ruby1, ruby2])
      end
    end

    context "other" do
      let(:given_platforms) { "foo" }

      it "is empty" do
        expect(scoped_collection).to be_empty
      end
    end

    context "multiple" do
      let(:given_platforms) { %w[RubyGems NPm] }

      it "can match any" do
        expect(scoped_collection).to match_array([ruby1, ruby2, npm1])
      end
    end
  end

  describe "#repository_sources" do
    subject(:project) { create(:project) }

    let!(:version_one) { create(:version, project: project, repository_sources: %w[a b]) }
    let!(:version_two) { create(:version, project: project, repository_sources: %w[b c]) }
    let!(:version_three) { create(:version, project: project, repository_sources: [nil, "d"]) }

    before do
      # Unfortunately there's some interaction between Project, Version, and
      # their hooks that cause the project's versions association to be cached
      # with no versions. Force-reload the project so the above created
      # versions can be found.
      project.reload
    end

    it "returns repository sources" do
      expect(project.repository_sources).to contain_exactly("a", "b", "c", "d")
    end
  end

  describe "#find_version" do
    subject(:project) { create(:project) }

    let(:version) { nil }

    context "without associated versions" do
      context "with nil version" do
        it "returns nil" do
          expect(project.find_version(version)).to be(nil)
        end
      end

      context "with specified missing version" do
        let(:version) { "1.2.3" }

        it "returns nil" do
          expect(project.find_version("1.2.3")).to be(nil)
        end
      end
    end

    context "with associated versions" do
      let(:target_found_version) { "1.0.0" }

      let!(:version_one) { create(:version, number: target_found_version, project: project, created_at: 1.day.ago) }
      let!(:version_two) { create(:version, number: "2.0.0", project: project, created_at: 1.hour.ago) }

      context "without association loaded" do
        context "with nil version" do
          it "returns nil" do
            expect(project.find_version(version)).to be(nil)
          end
        end

        context "with specific version" do
          let(:version) { target_found_version }

          it "returns the found version" do
            result = nil
            expect { result = project.find_version(version) }.to make_database_queries(count: 1)

            expect(result).to eq(version_one)
          end
        end
      end

      context "with association loaded and specific version" do
        let(:version) { target_found_version }

        before do
          # Clear out the old association data, then cache the new data
          project.reload
          ActiveRecord::Associations::Preloader.new(records: [project], associations: :versions).call
        end

        it "returns the found version" do
          result = nil
          expect { result = project.find_version(version) }.not_to make_database_queries

          expect(result).to eq(version_one)
        end
      end
    end
  end

  describe "#update_details" do
    let!(:project) do
      create(:project, name: "foo", platform: PackageManager::Rubygems,
                       repository_url: "https://github.com/foo/bar",
                       homepage: "http://example.com")
    end

    # the specific bug we added this spec to check for was setting latest_release_published_at to
    # updated_at when there were no versions on a project, which resulted in constantly increasing
    # the latest_release_published_at when there wasn't a release at all...
    it "does not keep changing stuff when nothing changed" do
      # run it once because apparently we don't on create?
      # should probably fix that... but don't want to risk it
      # at the time of working on this.
      project.update_details
      project.save!
      expect do
        project.update_details
        project.save!
      end.to not_change(project, :latest_release_published_at)
        .and not_change(project, :updated_at)
    end
  end

  describe "#send_project_updated" do
    let!(:project) do
      p = create(:project, name: "foo", platform: PackageManager::Rubygems,
                           repository_url: "https://github.com/foo/bar",
                           homepage: "http://example.com")
      # this is because the Project.update_details callback doesn't run on create, which is probably
      # not quite right honestly, but beyond the scope of the commit where I'm adding this.
      p.save!
      p
    end
    let(:url) { "https://example.com/hook" }
    let!(:web_hook) { create(:web_hook, url: url, all_project_updates: true, shared_secret: nil) }

    it "is called on touch and queues webhook" do
      allow(StructuredLog).to receive(:capture)
      allow(ProjectUpdatedWorker).to receive(:perform_async)
      expect do
        project.touch
      end.to change(project, :updated_at)
      expect(ProjectUpdatedWorker).to have_received(:perform_async).with(project.id, web_hook.id)

      expect(StructuredLog).to have_received(:capture).with(
        "WEB_HOOK_ABOUT_TO_QUEUE",
        {
          webhook_id: web_hook.id,
          project_id: project.id,
          project_platform: project.platform,
          project_name: project.name,
        }
      )
    end

    it "is not called when there's a no-op update" do
      allow(ProjectUpdatedWorker).to receive(:perform_async)
      expect do
        project.update(repository_url: project.repository_url, homepage: project.homepage)
      end.not_to change(project, :updated_at)
      expect(ProjectUpdatedWorker).not_to have_received(:perform_async).with(project.id, web_hook.id)
    end
  end
end
