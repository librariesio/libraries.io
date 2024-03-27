# frozen_string_literal: true

class RepositoryHost::Github::GithubRepositoryHostDataFactory
  def self.generate_from_api(upstream_repository_data_hash)
    input_hash = {
      repository_uuid: upstream_repository_data_hash[:id],
      archived: upstream_repository_data_hash[:archived],
      default_branch: upstream_repository_data_hash[:default_branch],
      description: upstream_repository_data_hash[:description],
      fork: upstream_repository_data_hash[:fork],
      full_name: upstream_repository_data_hash[:full_name],
      has_issues: upstream_repository_data_hash[:has_issues],
      has_wiki: upstream_repository_data_hash[:has_wiki],
      homepage: upstream_repository_data_hash[:homepage],
      host_type: "GitHub",
      keywords: upstream_repository_data_hash[:topics],
      language: upstream_repository_data_hash[:language],
      license: upstream_repository_data_hash.dig(:license, :key),
      name: upstream_repository_data_hash[:name],
      owner: upstream_repository_data_hash[:owner],
      parent: upstream_repository_data_hash[:parent],
      is_private: upstream_repository_data_hash[:private],
      scm: "git",
      repository_size: upstream_repository_data_hash[:size],
    }

    RepositoryHost::RawUpstreamData.new(**input_hash)
  end
end
