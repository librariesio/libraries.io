# frozen_string_literal: true

require "rails_helper"

describe RepositoryHost::Github do
  let(:repository) { build(:repository, host_type: "GitLab", full_name: "vuejs/vue") }
  let(:repository_host) { described_class.new(repository) }
  let(:api_token) { "TEST_TOKEN" }

  it "can fetch repository data" do
    VCR.use_cassette("github/vue") do
      repository_data = described_class.fetch_repo(repository.id_or_name, api_token)
      expect(repository_data).not_to be_nil
    end
  end

  it "maps data" do
    VCR.use_cassette("github/vue") do
      repository_data = repository_host.class.fetch_repo(repository.id_or_name, api_token)

      expect(repository_data.archived).to be false
      expect(repository_data.code_of_conduct_url).to eql("https://github.com/vuejs/vue/blob/main/.github/CODE_OF_CONDUCT.md")
      expect(repository_data.contribution_guidelines_url).to eql("https://github.com/vuejs/vue/blob/main/.github/CONTRIBUTING.md")
      expect(repository_data.default_branch).to eql("main")
      expect(repository_data.description).to eql("This is the repo for Vue 2. For Vue 3, go to https://github.com/vuejs/core")
      expect(repository_data.fork).to be false
      expect(repository_data.fork_policy).to be_nil
      expect(repository_data.forks_count).to eql(33596)
      expect(repository_data.full_name).to eql("vuejs/vue")
      expect(repository_data.funding_urls).to match_array(["https://github.com/yyx990803", "https://github.com/posva", "https://patreon.com/evanyou", "https://opencollective.com/vuejs", "https://tidelift.com/funding/github/npm/vue"])
      expect(repository_data.has_issues).to be true
      expect(repository_data.has_pages).to be false
      expect(repository_data.has_wiki).to be true
      expect(repository_data.homepage).to eql("http://v2.vuejs.org")
      expect(repository_data.host_type).to eql("GitHub")
      expect(repository_data.keywords).to match_array(%w[framework frontend javascript vue])
      expect(repository_data.language).to eql("TypeScript")
      expect(repository_data.license).to eql("mit")
      expect(repository_data.logo_url).to be_nil
      expect(repository_data.mirror_url).to be_nil
      expect(repository_data.name).to eql("vue")
      expect(repository_data.open_issues_count).to eql(603)
      expect(repository_data.owner).not_to be_nil
      expect(repository_data.parent).to be_nil
      expect(repository_data.is_private).to be false
      expect(repository_data.pull_requests_enabled).to be_nil
      expect(repository_data.pushed_at.iso8601).to eql("2024-03-14T17:24:41Z")
      expect(repository_data.repository_uuid).to eql("11730342")
      expect(repository_data.scm).to eql("git")
      expect(repository_data.security_policy_url).to eql("https://github.com/vuejs/vue/blob/main/.github/SECURITY.md")
      expect(repository_data.stargazers_count).to eql(206_637)
      expect(repository_data.subscribers_count).to eql(5912)
      expect(repository_data.repository_size).to eql(32405)
    end
  end
end
