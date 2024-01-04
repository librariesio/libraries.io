# frozen_string_literal: true

require "rails_helper"

describe Repository, type: :model do
  it { should have_many(:projects) }
  it { should have_many(:contributions) }
  it { should have_many(:contributors) }
  it { should have_many(:tags) }
  it { should have_many(:published_tags) }
  it { should have_many(:manifests) }
  it { should have_many(:dependencies) }
  it { should have_many(:forked_repositories) }
  it { should have_many(:repository_subscriptions) }
  it { should have_many(:web_hooks) }
  it { should have_one(:readme) }
  it { should belong_to(:repository_organisation) }
  it { should belong_to(:repository_user) }
  it { should belong_to(:source) }

  it { should validate_uniqueness_of(:full_name).scoped_to(:host_type) }
  it { should validate_uniqueness_of(:uuid).scoped_to(:host_type) }

  describe "#domain" do
    it "should be https://github.com for GitHub repos" do
      expect(Repository.new(host_type: "GitHub").domain).to eq("https://github.com")
    end

    it "should be https://gitlab.com for GitLab repos" do
      expect(Repository.new(host_type: "GitLab").domain).to eq("https://gitlab.com")
    end

    it "should be https://bitbucket.org for Bitbucket repos" do
      expect(Repository.new(host_type: "Bitbucket").domain).to eq("https://bitbucket.org")
    end
  end

  describe "#url" do
    it "should be https://github.com/:full_name for GitHub repos" do
      expect(Repository.new(host_type: "GitHub", full_name: "rails/rails").url).to eq("https://github.com/rails/rails")
    end

    it "should be https://gitlab.com/:full_name for GitLab repos" do
      expect(Repository.new(host_type: "GitLab", full_name: "rails/rails").url).to eq("https://gitlab.com/rails/rails")
    end

    it "should be https://bitbucket.org/:full_name for Bitbucket repos" do
      expect(Repository.new(host_type: "Bitbucket", full_name: "rails/rails").url).to eq("https://bitbucket.org/rails/rails")
    end
  end

  describe "#watchers_url" do
    it "should be https://github.com/:full_name/watchers for GitHub repos" do
      expect(Repository.new(host_type: "GitHub", full_name: "rails/rails").watchers_url).to eq("https://github.com/rails/rails/watchers")
    end

    it "should be nil for GitLab repos" do
      expect(Repository.new(host_type: "GitLab", full_name: "rails/rails").watchers_url).to eq(nil)
    end

    it "should be nil for Bitbucket repos" do
      expect(Repository.new(host_type: "Bitbucket", full_name: "rails/rails").watchers_url).to eq(nil)
    end
  end

  describe "#stargazers_url" do
    it "should be https://github.com/:full_name/stargazers for GitHub repos" do
      expect(Repository.new(host_type: "GitHub", full_name: "rails/rails").stargazers_url).to eq("https://github.com/rails/rails/stargazers")
    end

    it "should be nil for GitLab repos" do
      expect(Repository.new(host_type: "GitLab", full_name: "rails/rails").stargazers_url).to eq(nil)
    end

    it "should be nil for Bitbucket repos" do
      expect(Repository.new(host_type: "Bitbucket", full_name: "rails/rails").stargazers_url).to eq(nil)
    end
  end

  describe "#forks_url" do
    it "should be https://github.com/:full_name/network for GitHub repos" do
      expect(Repository.new(host_type: "GitHub", full_name: "rails/rails").forks_url).to eq("https://github.com/rails/rails/network")
    end

    it "should be https://gitlab.com/:full_name/forks for GitLab repos" do
      expect(Repository.new(host_type: "GitLab", full_name: "rails/rails").forks_url).to eq("https://gitlab.com/rails/rails/forks")
    end

    it "should be nil for Bitbucket repos" do
      expect(Repository.new(host_type: "Bitbucket", full_name: "rails/rails").forks_url).to eq(nil)
    end
  end

  describe "#issues_url" do
    it "should be https://github.com/:full_name/issues for GitHub repos" do
      expect(Repository.new(host_type: "GitHub", full_name: "rails/rails").issues_url).to eq("https://github.com/rails/rails/issues")
    end

    it "should be https://gitlab.com/:full_name/issues for GitLab repos" do
      expect(Repository.new(host_type: "GitLab", full_name: "rails/rails").issues_url).to eq("https://gitlab.com/rails/rails/issues")
    end

    it "should be https://bitbucket.org/:full_name/issues for Bitbucket repos" do
      expect(Repository.new(host_type: "Bitbucket", full_name: "rails/rails").issues_url).to eq("https://bitbucket.org/rails/rails/issues")
    end
  end

  describe "#contributors_url" do
    it "should be https://github.com/:full_name/graphs/contributors for GitHub repos" do
      expect(build(:repository, host_type: "GitHub").contributors_url).to eq("https://github.com/rails/rails/graphs/contributors")
    end

    it "should be https://gitlab.com/:full_name/graphs/master for GitLab repos" do
      expect(build(:repository, host_type: "GitLab").contributors_url).to eq("https://gitlab.com/rails/rails/graphs/master")
    end

    it "should be nil for Bitbucket repos" do
      expect(build(:repository, host_type: "Bitbucket").contributors_url).to eq(nil)
    end
  end

  describe "#blob_url" do
    context "with no args" do
      it "should be https://github.com/:full_name/blob/master/ for GitHub repos" do
        expect(build(:repository, host_type: "GitHub").blob_url).to eq("https://github.com/rails/rails/blob/master/")
      end

      it "should be https://gitlab.com/:full_name/blob/master for GitLab repos" do
        expect(build(:repository, host_type: "GitLab").blob_url).to eq("https://gitlab.com/rails/rails/blob/master/")
      end

      it "should be https://bitbucket.org/:full_name/src/master/ for Bitbucket repos" do
        expect(build(:repository, host_type: "Bitbucket").blob_url).to eq("https://bitbucket.org/rails/rails/src/master/")
      end
    end
  end

  describe "#source_url" do
    it "should be https://github.com/:source_name for GitHub repos" do
      expect(Repository.new(host_type: "GitHub", source_name: "fails/fails").source_url).to eq("https://github.com/fails/fails")
    end

    it "should be https://gitlab.com/:source_name for GitLab repos" do
      expect(Repository.new(host_type: "GitLab", source_name: "fails/fails").source_url).to eq("https://gitlab.com/fails/fails")
    end

    it "should be https://bitbucket.org/:source_name for Bitbucket repos" do
      expect(Repository.new(host_type: "Bitbucket", source_name: "fails/fails").source_url).to eq("https://bitbucket.org/fails/fails")
    end
  end

  describe "#raw_url" do
    context "with no args" do
      it "should be https://github.com/:full_name/raw/master/ for GitHub repos" do
        expect(build(:repository, host_type: "GitHub").raw_url).to eq("https://github.com/rails/rails/raw/master/")
      end

      it "should be https://gitlab.com/:full_name/raw/master for GitLab repos" do
        expect(build(:repository, host_type: "GitLab").raw_url).to eq("https://gitlab.com/rails/rails/raw/master/")
      end

      it "should be https://bitbucket.org/:full_name/raw/master/ for Bitbucket repos" do
        expect(build(:repository, host_type: "Bitbucket").raw_url).to eq("https://bitbucket.org/rails/rails/raw/master/")
      end
    end
  end

  describe "#commits_url" do
    context "with no args" do
      it "should be https://github.com/:full_name/raw/master/ for GitHub repos" do
        expect(build(:repository, host_type: "GitHub").commits_url).to eq("https://github.com/rails/rails/commits")
      end

      it "should be https://gitlab.com/:full_name/raw/master for GitLab repos" do
        expect(build(:repository, host_type: "GitLab").commits_url).to eq("https://gitlab.com/rails/rails/commits/master")
      end

      it "should be https://bitbucket.org/:full_name/raw/master/ for Bitbucket repos" do
        expect(build(:repository, host_type: "Bitbucket").commits_url).to eq("https://bitbucket.org/rails/rails/commits")
      end
    end
  end

  describe "#avatar_url" do
    context "with no args" do
      it "should return an avatar url for GitHub repos" do
        expect(build(:repository, host_type: "GitHub").avatar_url).to eq("https://github.com/rails.png?size=60")
      end

      it "should return an avatar url for GitLab repos" do
        expect(build(:repository, host_type: "GitLab").avatar_url).to eq("https://www.gravatar.com/avatar/7ae482ea784951c2d4bb56fc642619b7?s=60&f=y&d=retro")
      end

      it "should return an avatar url for Bitbucket repos" do
        expect(build(:repository, host_type: "Bitbucket").avatar_url).to eq("https://bitbucket.org/rails/rails/avatar/60")
      end
    end
  end

  describe "#gather_maintenance_stats" do
    let(:repository) { create(:repository, full_name: "chalk/chalk") }
    let!(:auth_token) { create(:auth_token) }
    let!(:project) do
      repository.projects.create!(
        name: "test-project",
        platform: "Maven",
        repository_url: "https://github.com/librariesio/libraries.io",
        homepage: "https://libraries.io"
      )
    end

    before do
      # set the value for DateTime.current so that the queries always have the same variables and can be matched in VCR
      allow(DateTime).to receive(:current).and_return(DateTime.parse("2018-12-14T17:49:49+00:00"))
    end

    # See docs/development-setup.md for details on re-recording VCR cassettes.
    #
    # GitHub API V3 calls can be matched with default :method and :uri.
    # GitHub API V4 calls all use the same endpoint, but have unique request bodies with the GraphQL queries. They will need to match on :body.
    context "with a valid repository" do
      before do
        VCR.use_cassette("github/chalk_api", match_requests_on: %i[method uri body query]) do
          repository.gather_maintenance_stats
        end
      end

      it "should save metrics for repository" do
        maintenance_stats = repository.repository_maintenance_stats
        expect(repository.maintenance_stats_refreshed_at).to_not be_nil
        expect(maintenance_stats.count).to be > 0

        maintenance_stats.each do |stat|
          # every stat should have a value
          expect(stat.value).to_not be nil
        end
      end

      it "should update existing stats" do
        first_updated_at = repository.repository_maintenance_stats.first.updated_at
        category = repository.repository_maintenance_stats.first.category

        VCR.use_cassette("github/chalk_api", match_requests_on: %i[method uri body query]) do
          repository.gather_maintenance_stats
        end

        updated_stat = repository.repository_maintenance_stats.find_by(category: category)
        expect(updated_stat).to_not be nil
        expect(updated_stat.updated_at).to be > first_updated_at
      end
    end

    context "with invalid repository" do
      let(:repository) { create(:repository, full_name: "bad/example-for-testing") }

      it "should not save metrics for repository" do
        allow(StructuredLog).to receive(:capture).and_call_original

        VCR.use_cassette("github/bad_repository", match_requests_on: %i[method uri body query]) do
          expect { repository.gather_maintenance_stats }.to raise_error(MaintenanceStats::Queries::QueryUtils::QueryError)
        end

        maintenance_stats = repository.repository_maintenance_stats
        expect(maintenance_stats.count).to be 0
        # we should update the refreshed_at time even with a query error
        expect(repository.maintenance_stats_refreshed_at).not_to be_nil
        expect(StructuredLog).to have_received(:capture).with(
          "GITHUB_STAT_QUERY_ERROR",
          hash_including(
            repository_name: repository.full_name,
            error_messages: array_including("Could not resolve to a Repository with the name '#{repository.full_name}'.")
          )
        )
      end
    end

    context "with empty repository" do
      let(:repository) { create(:repository, full_name: "buddhamagnet/heidigoodchild") }

      it "should save default values" do
        VCR.use_cassette("github/empty_repository", match_requests_on: %i[method uri body query]) do
          repository.gather_maintenance_stats
        end

        maintenance_stats = repository.repository_maintenance_stats
        non_zeros = {
          issue_closure_rate: "1.0",
          pull_request_acceptance: "1.0",
          one_year_issue_closure_rate: "1.0",
          one_year_pull_request_closure_rate: "1.0",
          issues_stats_truncated: "false",
        }
        expect(maintenance_stats.count).to be > 0
        maintenance_stats.each do |stat|
          should_be = non_zeros.fetch(stat.category.to_sym, "0")
          expect(stat.value).to eql should_be
        end
      end
    end

    context "with non GitHub repository" do
      let(:repository) { create(:repository, host_type: "Gitlab") }

      it "should not save any values" do
        repository.gather_maintenance_stats

        maintenance_stats = repository.repository_maintenance_stats
        expect(maintenance_stats.count).to be 0
        expect(repository.maintenance_stats_refreshed_at).to be_nil
      end
    end
  end

  describe "#sync_manifest" do
    let(:repository) { create(:repository) }
    before do
      es_double = instance_double(
        "Elasticsearch::Model::Indexing::InstanceMethods",
        index_document: -> { true }
      )
      expect_any_instance_of(Repository)
        .to receive(:__elasticsearch__)
        .at_least(1)
        .and_return(es_double)
    end

    it "should create a manifest with deps if it doesn't exist" do
      expect do
        repository.sync_manifest({
                                   platform: "cargo",
                                   path: "Cargo.lock",
                                   dependencies: [{ name: "Inflector", requirement: "0.11.4", type: "runtime" }],
                                   sha: "abcd1234",
                                 })
      end.to change { repository.manifests.count }.by(1)

      manifest = repository.manifests.first
      expect(manifest.filepath).to eq("Cargo.lock")
      expect(manifest.repository_dependencies.pluck(:project_name)).to eq(["Inflector"])
      expect(manifest.repository_dependencies.pluck(:requirements)).to eq(["0.11.4"])
    end

    it "should not raise an exception when the manifest had an error" do
      expect do
        repository.sync_manifest({
                                   platform: "cargo",
                                   path: "Cargo.lock",
                                   dependencies: nil,
                                   sha: "abcd1234",
                                   error_message: "Cargo.lock: key not found: \"dev-dependencies\"\nDid you mean? \"dependencies\"",
                                 })
      end.to change { repository.manifests.count }.by(0)
    end
  end
end
