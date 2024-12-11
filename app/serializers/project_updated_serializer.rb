# frozen_string_literal: true

class ProjectUpdatedSerializer < ActiveModel::Serializer
  # Don't add anything here that requires a join.
  #  - join to Version will be too slow for high-release-count projects
  #  - join to Repository assumes Project.repository_id is correct
  attributes %i[
    created_at
    dependents_count
    homepage
    keywords_array
    latest_release_number
    latest_release_published_at
    latest_stable_release_number
    name
    platform
    repository_url
    status
    updated_at
    versions_count
  ]
end
