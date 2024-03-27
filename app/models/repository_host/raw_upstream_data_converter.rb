# frozen_string_literal: true

class RepositoryHost::RawUpstreamDataConverter
  def self.convert_from_github_api(upstream_repository_data_hash)
    RepositoryHost::RawUpstreamData.new(
      repository_uuid: upstream_repository_data_hash[:id].to_s,
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
      repository_size: upstream_repository_data_hash[:size]
    )
  end

  def self.convert_from_gitlab_api(api_project)
    RepositoryHost::RawUpstreamData.new(
      repository_uuid: api_project.id.to_s,
      description: api_project.description,
      name: api_project.name,
      default_branch: api_project.default_branch,
      archived: api_project.archived,
      host_type: "GitLab",
      full_name: api_project.path_with_namespace,
      owner: {},
      fork: api_project.try(:forked_from_project).present?,
      has_issues: api_project.issues_enabled,
      has_wiki: api_project.wiki_enabled,
      scm: "git",
      is_private: api_project.visibility != "public",
      keywords: api_project.topics,
      parent: {
        full_name: api_project.try(:forked_from_project).try(:path_with_namespace),
      },
      homepage: api_project.web_url,
      license: api_project.license.key,
      repository_size: 0, # locked to admins only?,
      language: nil # separate API endpoint that doesn't seem to be supported by the API gem we use
    )
  end

  def self.convert_from_bitbucket_api(api_project)
    RepositoryHost::RawUpstreamData.new(
      description: api_project.description,
      language: api_project.language,
      full_name: api_project.full_name,
      name: api_project.name,
      has_wiki: api_project.has_wiki,
      has_issues: api_project.has_issues,
      scm: api_project.scm,
      repository_uuid: api_project.uuid.to_s,
      host_type: "Bitbucket",
      owner: api_project.owner,
      homepage: api_project.website,
      fork: api_project.parent.present?,
      default_branch: api_project.fetch("mainbranch", {}).try(:fetch, "name", nil),
      is_private: api_project.is_private,
      repository_size: api_project[:size].to_f / 1000,
      parent: {
        full_name: api_project.fetch("parent", {}).try(:fetch, "full_name", nil),
      },
      archived: false,
      keywords: [],
      license: nil
    )
  end
end
