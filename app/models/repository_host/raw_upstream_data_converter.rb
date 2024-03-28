# frozen_string_literal: true

class RepositoryHost::RawUpstreamDataConverter
  def self.convert_from_github_api(upstream_repository_data_hash)
    RepositoryHost::RawUpstreamData.new(
      archived: upstream_repository_data_hash[:archived],
      default_branch: upstream_repository_data_hash[:default_branch],
      description: upstream_repository_data_hash[:description],
      fork: upstream_repository_data_hash[:fork],
      fork_policy: upstream_repository_data_hash[:fork_policy],
      forks_count: upstream_repository_data_hash[:forks_count],
      full_name: upstream_repository_data_hash[:full_name],
      has_issues: upstream_repository_data_hash[:has_issues],
      has_pages: upstream_repository_data_hash[:has_pages],
      has_wiki: upstream_repository_data_hash[:has_wiki],
      homepage: upstream_repository_data_hash[:homepage],
      host_type: "GitHub",
      keywords: upstream_repository_data_hash[:topics],
      language: upstream_repository_data_hash[:language],
      license: upstream_repository_data_hash.dig(:license, :key),
      logo_url: upstream_repository_data_hash[:logo_url],
      mirror_url: upstream_repository_data_hash[:mirror_url],
      name: upstream_repository_data_hash[:name],
      open_issues_count: upstream_repository_data_hash[:open_issues_count],
      owner: upstream_repository_data_hash[:owner],
      parent: upstream_repository_data_hash[:parent],
      pull_requests_enabled: upstream_repository_data_hash[:pull_requests_enabled],
      pushed_at: upstream_repository_data_hash[:pushed_at],
      is_private: upstream_repository_data_hash[:private],
      scm: "git",
      stargazers_count: upstream_repository_data_hash[:stargazers_count],
      subscribers_count: upstream_repository_data_hash[:subscribers_count],
      repository_size: upstream_repository_data_hash[:size],
      repository_uuid: upstream_repository_data_hash[:id].to_s
    )
  end

  def self.convert_from_gitlab_api(api_project)
    RepositoryHost::RawUpstreamData.new(
      archived: api_project.archived,
      default_branch: api_project.default_branch,
      description: api_project.description,
      fork: api_project.try(:forked_from_project).present?,
      fork_policy: nil,
      forks_count: api_project.forks_count,
      full_name: api_project.path_with_namespace,
      has_issues: api_project.issues_enabled,
      has_pages: nil,
      has_wiki: api_project.wiki_enabled,
      homepage: api_project.web_url,
      host_type: "GitLab",
      is_private: api_project.visibility != "public",
      keywords: api_project.topics,
      language: nil, # separate API endpoint that doesn't seem to be supported by the API gem we use,
      license: api_project.license.key,
      logo_url: api_project.avatar_url,
      mirror_url: nil,
      name: api_project.name,
      parent: {
        full_name: api_project.try(:forked_from_project).try(:path_with_namespace),
      },
      pull_requests_enabled: api_project.merge_requests_enabled,
      open_issues_count: api_project.open_issues_count,
      owner: {},
      pushed_at: api_project.last_activity_at,
      repository_size: 0, # locked to admins only?,
      repository_uuid: api_project.id.to_s,
      scm: "git",
      stargazers_count: api_project.star_count,
      subscribers_count: nil
    )
  end

  def self.convert_from_bitbucket_api(api_project, forks_response)
    RepositoryHost::RawUpstreamData.new(
      archived: false,
      default_branch: api_project.fetch("mainbranch", {}).try(:fetch, "name", nil),
      description: api_project.description,
      fork: api_project.parent.present?,
      fork_policy: api_project.fork_policy,
      forks_count: forks_response.fetch("size", 0),
      full_name: api_project.full_name,
      has_issues: api_project.has_issues,
      has_pages: nil,
      has_wiki: api_project.has_wiki,
      homepage: api_project.website,
      host_type: "Bitbucket",
      is_private: api_project.is_private,
      keywords: [],
      language: api_project.language,
      license: nil,
      logo_url: nil,
      mirror_url: nil,
      name: api_project.name,
      open_issues_count: nil,
      owner: api_project.owner,
      parent: {
        full_name: api_project.fetch("parent", {}).try(:fetch, "full_name", nil),
      },
      pull_requests_enabled: true,
      pushed_at: nil,
      repository_size: api_project[:size].to_f / 1000,
      repository_uuid: api_project.uuid.to_s,
      scm: api_project.scm,
      stargazers_count: nil,
      subscribers_count: nil # need an update to our BitBucket API gem to get list of repo watchers
    )
  end
end
