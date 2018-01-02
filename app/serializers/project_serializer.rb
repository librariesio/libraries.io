class ProjectSerializer < ActiveModel::Serializer
  cache
  delegate :cache_key, to: :object

  attributes :name, :platform, :description, :homepage, :repository_url,
             :normalized_licenses, :rank, :latest_release_published_at,
             :latest_release_number, :language, :status, :package_manager_url,
             :stars, :forks, :keywords, :latest_stable_release

  has_many :versions
end
