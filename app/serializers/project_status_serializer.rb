class ProjectStatusSerializer < ActiveModel::Serializer
  attributes Project::API_FIELDS
  attributes :package_manager_url, :stars, :forks, :keywords, :latest_download_url
  attribute :score, if: :score?

  has_many :versions
  has_many :repository_maintenance_stats, if: :show_stats?

  def score?
    instance_options[:show_score]
  end

  def show_stats?
    instance_options[:show_stats]
  end

  def name
    instance_options[:project_names][object.name]
  end
end
