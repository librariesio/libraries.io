# frozen_string_literal: true

# This class is meant to be a facade over the raw upstream data coming
# from the different repository hosts' repository data. It's main goal
# is to standardize the output from each repository host into a concrete
# set of data so we can make sure the raw data is being mapped to the same
# schema within the Libraries.io models and code.
RepositoryHost::RawUpstreamData = Struct.new(
  :archived, :default_branch, :description, :fork, :fork_policy, :forks_count, :full_name, :has_issues, :has_pages,
  :has_wiki, :homepage, :host_type, :is_private, :keywords, :language, :license, :logo_url, :mirror_url,
  :name, :open_issues_count, :owner, :parent, :pull_requests_enabled, :pushed_at, :repository_uuid, :scm,
  :stargazers_count, :subscribers_count, :repository_size,
  keyword_init: true
) do
  def to_repository_attrs
    attrs = {
      default_branch: default_branch,
      description: description,
      fork: fork,
      fork_policy: fork_policy,
      forks_count: forks_count,
      full_name: full_name,
      has_issues: has_issues,
      has_pages: has_pages,
      has_wiki: has_wiki,
      homepage: homepage,
      host_type: host_type,
      keywords: keywords,
      language: language,
      license: formatted_license,
      logo_url: logo_url,
      mirror_url: mirror_url,
      name: name,
      open_issues_count: open_issues_count,
      private: is_private,
      pull_requests_enabled: pull_requests_enabled,
      pushed_at: pushed_at,
      scm: scm,
      size: repository_size,
      stargazers_count: stargazers_count,
      subscribers_count: subscribers_count,
      uuid: repository_uuid,
    }
    attrs[:source_name] = source_name if fork

    attrs
  end

  def formatted_license
    if license
      Project.format_license(license)
    end
  end

  def source_name
    parent&.fetch(:full_name, nil)
  end

  def lower_name
    full_name&.downcase
  end
end
