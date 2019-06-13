class Api::StatusController < Api::ApplicationController
  before_action :require_api_key

  def check
    if params[:projects].any?
      # Try to get all the projects passed in.
      @projects = params[:projects]
        .group_by { |project| project[:platform] }
        .flat_map { |platform, projects| find_projects(projects, platform) }
        .compact
    else
      @projects = []
    end
    render json: @projects, each_serializer: ProjectStatusSerializer, show_score: params[:score], show_stats: internal_api_key?
  end

  private

  def find_projects(projects, platform)
    projects.each_slice(1000).flat_map do |slice|
      project_find_names = slice.flat_map { |project| project_names(project, platform) }.map(&:downcase)
      Project.platform(platform).where('lower(platform)=? AND lower(name) in (?)', platform.downcase, project_find_names).includes(:repository, :versions, :repository_maintenance_stats)
    end
  end

  def project_names(project, platform)
    begin
      "PackageManager::#{platform.capitalize}".constantize.project_find_names(project[:name])
    rescue => exception
      PackageManager::Base.project_find_names(project[:name])
    end
  end
end
