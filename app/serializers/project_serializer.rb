# frozen_string_literal: true

class ProjectSerializer < ActiveModel::Serializer
  attributes %i[
    contributions_count
    dependent_repos_count
    dependents_count
    deprecation_reason
    description
    forks
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
    stars
    status
  ]

  has_many :versions

  attribute :updated_at, if: :show_updated_at?

  def show_updated_at?
    instance_options[:show_updated_at]
  end
end
