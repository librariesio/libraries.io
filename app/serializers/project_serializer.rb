class ProjectSerializer < ActiveModel::Serializer
  attributes :name, :platform, :description, :language, :homepage,
             :repository_url, :normalized_licenses, :rank, :status,
             :latest_release_number, :latest_release_published_at,
             :package_manager_url, :stars, :forks, :keywords,
             :latest_stable_release
  has_many :versions
end
