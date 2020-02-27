class ProjectSerializer < ActiveModel::Serializer
  attributes %i[
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
    latest_stable_release
    latest_stable_release_number
    latest_stable_release_published_at
    license_normalized
    licenses
    name
    normalized_licenses
    package_manager_url
    platform
    rank
    repository_url
    stars
    status
  ]

  has_many :versions
end
