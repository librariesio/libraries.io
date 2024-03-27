# frozen_string_literal: true

require "rails_helper"

describe RepositoryHost::Gitlab do
  let(:repository) { build(:repository, host_type: "GitLab", full_name: "ase/ase") }
  let(:repository_host) { described_class.new(repository) }
  let(:api_token) { "TEST_TOKEN" }

  it "can fetch repository data" do
    VCR.use_cassette("gitlab/ase") do
      repository_data = described_class.fetch_repo(repository.id_or_name, api_token)
      expect(repository_data).not_to be_nil
    end
  end

  it "maps data" do
    VCR.use_cassette("gitlab/ase") do
      repository_data = repository_host.class.fetch_repo(repository.id_or_name, api_token)

      expect(repository_data.archived).to be false
      expect(repository_data.default_branch).to eql("master")
      expect(repository_data.description).to eql("[Atomic Simulation Environment](https://wiki.fysik.dtu.dk/ase/): A Python library for working with atoms")
      expect(repository_data.fork).to be false
      expect(repository_data.full_name).to eql("ase/ase")
      expect(repository_data.has_issues).to be true
      expect(repository_data.has_wiki).to be false
      expect(repository_data.homepage).to eql("https://gitlab.com/ase/ase")
      expect(repository_data.host_type).to eql("GitLab")
      expect(repository_data.keywords).to match_array(["Atomistic simulations", "chemistry", "materials", "physics"])
      expect(repository_data.language).to be_nil # not supported by our API calls at the moment
      expect(repository_data.license).to eql("lgpl-2.1")
      expect(repository_data.name).to eql("ase")
      expect(repository_data.owner).not_to be_nil
      expect(repository_data.parent).to match(hash_including(:full_name))
      expect(repository_data.is_private).to be false
      expect(repository_data.repository_uuid).to eql("470007")
      expect(repository_data.scm).to eql("git")
      expect(repository_data.repository_size).to eql(0) # size isn't availabe in the API
    end
  end
end
