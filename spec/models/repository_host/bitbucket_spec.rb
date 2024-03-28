# frozen_string_literal: true

require "rails_helper"

describe RepositoryHost::Bitbucket do
  let(:repository) { build(:repository, host_type: "Bitbucket", full_name: "codekoala/node-iostat") }
  let(:repository_host) { described_class.new(repository) }
  let(:api_token) { "TEST_TOKEN" }

  it "can fetch repository data" do
    VCR.use_cassette("bitbucket/node_iostat") do
      repository_data = repository_host.class.fetch_repo(repository.id_or_name, api_token)
      expect(repository_data).not_to be_nil
    end
  end

  it "maps data" do
    VCR.use_cassette("bitbucket/node_iostat") do
      repository_data = repository_host.class.fetch_repo(repository.id_or_name, api_token)

      expect(repository_data.archived).to be false
      expect(repository_data.default_branch).to eql("master")
      expect(repository_data.description).to eql("Uses Node.js and flot to produce a \"real-time\" graph of data from iostat.")
      expect(repository_data.fork).to be false
      expect(repository_data.fork_policy).to eql("allow_forks")
      expect(repository_data.forks_count).to eql(0)
      expect(repository_data.full_name).to eql("codekoala/node-iostat")
      expect(repository_data.has_issues).to be true
      expect(repository_data.has_pages).to be_nil
      expect(repository_data.has_wiki).to be false
      expect(repository_data.homepage).to eql("http://www.codekoala.com/")
      expect(repository_data.host_type).to eql("Bitbucket")
      expect(repository_data.keywords).to match_array([])
      expect(repository_data.language).to eql("javascript")
      expect(repository_data.license).to be_nil # license data isn't available via API
      expect(repository_data.logo_url).to be_nil # not available for bitbucket
      expect(repository_data.mirror_url).to be_nil
      expect(repository_data.name).to eql("node-iostat")
      expect(repository_data.open_issues_count).to be_nil
      expect(repository_data.owner).not_to be_nil
      expect(repository_data.parent).to match(hash_including(:full_name))
      expect(repository_data.is_private).to be false
      expect(repository_data.pull_requests_enabled).to be true
      expect(repository_data.pushed_at).to be_nil
      expect(repository_data.repository_uuid).to eql("{219c49b1-9aad-4b14-a697-b672377baebb}")
      expect(repository_data.scm).to eql("git")
      expect(repository_data.stargazers_count).to be_nil
      expect(repository_data.subscribers_count).to be_nil
      expect(repository_data.repository_size).to eql(118.925)
    end
  end
end
