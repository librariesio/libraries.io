# frozen_string_literal: true

class RepositoryHost::Bitbucket::BitbucketRepositoryHostDataFactory
  def self.generate_from_api(api_project)
    input_hash = {
      description: api_project.description,
      language: api_project.language,
      full_name: api_project.full_name,
      name: api_project.name,
      has_wiki: api_project.has_wiki,
      has_issues: api_project.has_issues,
      scm: api_project.scm,
      repository_uuid: api_project.uuid,
      host_type: "Bitbucket",
      owner: api_project.owner,
      homepage: api_project.website,
      fork: api_project.parent.present?,
      default_branch: api_project.fetch("mainbranch", {}).try(:fetch, "name", nil),
      private: api_project.is_private,
      size: api_project[:size].to_f / 1000,
      parent: {
        full_name: api_project.fetch("parent", {}).try(:fetch, "full_name", nil),
      },
      archived: false,
      keywords: [],
      license: nil,
    }

    RepositoryHost::RepositoryHostData.new(**input_hash)
  end
end
