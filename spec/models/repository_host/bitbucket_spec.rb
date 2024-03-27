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
end
