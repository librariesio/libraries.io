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
end
