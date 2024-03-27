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
      expect(repository_data.default_branch).to eql("main")
      expect(repository_data.description).to eql("This is the repo for Vue 2. For Vue 3, go to https://github.com/vuejs/core")
      expect(repository_data.fork).to be false
      expect(repository_data.full_name).to eql("vuejs/vue")
      expect(repository_data.has_issues).to be true
      expect(repository_data.has_wiki).to be true
      expect(repository_data.homepage).to eql("http://v2.vuejs.org")
      expect(repository_data.host_type).to eql("GitHub")
      expect(repository_data.keywords).to match_array(%w[framework frontend javascript vue])
      expect(repository_data.language).to eql("TypeScript")
      expect(repository_data.license).to eql("mit")
      expect(repository_data.name).to eql("vue")
      expect(repository_data.owner).not_to be_nil
      expect(repository_data.parent).to be_nil
      expect(repository_data.is_private).to be false
      expect(repository_data.repository_uuid).to eql("11730342")
      expect(repository_data.scm).to eql("git")
      expect(repository_data.repository_size).to eql(32405)
    end
  end
end
