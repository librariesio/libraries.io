# frozen_string_literal: true

class RepositoryHost::Gitlab::GitlabRepositoryHostDataFactory
  def self.generate_from_api(api_project)
    repo_hash = {
      repository_uuid: api_project.id,
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
      language: nil, # separate API endpoint that doesn't seem to be supported by the API gem we use
    }

    RepositoryHost::RepositoryHostData.new(**repo_hash)
  end
end
