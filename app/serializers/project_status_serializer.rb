class ProjectStatusSerializer < ActiveModel::Serializer
  attributes Project::API_FIELDS
  attributes %i[
    canonical_name
    forks
    keywords
    latest_download_url
    package_manager_url
    stars
    license_set_by_admin
    repository_license
  ]
  attribute :score, if: :score?

  has_many :versions
  has_many :repository_maintenance_stats, if: :show_stats?
  attribute :updated_at, if: :show_updated_at?

  def score?
    instance_options[:show_score]
  end

  def show_stats?
    instance_options[:show_stats]
  end

  def show_updated_at?
    instance_options[:show_updated_at]
  end

  def name
    instance_options[:project_names][[object.platform, object.name]]
  end

  def canonical_name
    object.name
  end

  def repository_license
    object.repository&.license
  end
end
