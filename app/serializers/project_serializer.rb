class ProjectSerializer < ActiveModel::Serializer
  attributes :name, :platform, :description, :homepage, :repository_url,
             :normalized_licenses, :rank, :latest_release_published_at,
             :latest_release_number, :language, :status, :package_manager_url,
             :stars, :forks, :keywords, :latest_stable_release,
             :dependents_count, :dependent_repos_count

  has_many :versions
end
