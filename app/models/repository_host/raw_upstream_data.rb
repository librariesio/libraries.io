# frozen_string_literal: true

# This class is meant to be a facade over the raw upstream data coming
# from the different repository hosts' repository data. It's main goal
# is to standardize the output from each repository host into a concrete
# set of data so we can make sure the raw data is being mapped to the same
# schema within the Libraries.io models and code.
RepositoryHost::RawUpstreamData = Struct.new(
  :archived, :code_of_conduct_url, :contribution_guidelines_url, :default_branch, :description, :fork,
  :fork_policy, :forks_count, :full_name, :funding_urls, :has_issues, :has_pages,
  :has_wiki, :homepage, :host_type, :is_private, :keywords, :language, :license, :logo_url, :mirror_url,
  :name, :open_issues_count, :owner, :parent, :pull_requests_enabled, :pushed_at, :repository_uuid, :scm,
  :security_policy_url, :stargazers_count, :subscribers_count, :repository_size,
  keyword_init: true
) do
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
