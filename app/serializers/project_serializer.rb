# frozen_string_literal: true

class ProjectSerializer < ActiveModel::Serializer
  attributes %i[
    code_of_conduct_url
    contributions_count
    contribution_guidelines_url
    dependent_repos_count
    dependents_count
    deprecation_reason
    description
    forks
    funding_urls
    homepage
    keywords
    language
    latest_download_url
    latest_release_number
    latest_release_published_at
    latest_stable_release_number
    latest_stable_release_published_at
    license_normalized
    licenses
    name
    normalized_licenses
    package_manager_url
    platform
    rank
    repository_license
    repository_status
    repository_url
    security_policy_url
    stars
    status
  ]

  has_many :versions, if: :include_versions?

  attribute :updated_at, if: :show_updated_at?

  def include_versions?
    instance_options.fetch(:include_versions, true)
  end

  def show_updated_at?
    instance_options[:show_updated_at]
  end
end
