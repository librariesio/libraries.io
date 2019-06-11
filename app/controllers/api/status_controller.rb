class Api::StatusController < Api::ApplicationController
  before_action :require_api_key

  def check
    if params[:projects].any?
      # Try to get all the projects passed in.
      @projects = params[:projects].group_by{|project| project[:platform] }.map do |platform, projects|
        projects.each_slice(1000).map{|slice| find_projects(slice, platform)}
      end.flatten.compact
    else
      @projects = []
    end
    render json: @projects, each_serializer: ProjectStatusSerializer, show_score: params[:score], show_stats: internal_api_key?
  end

  private

  def find_projects(projects, platform)
    project_find_names = projects.map{|project| project_names(project, platform)}
    Project.platform(platform).where(name: project_find_names).includes(:repository, :versions, :repository_maintenance_stats)
  end

  def project_names(project, platform)
    begin
      "PackageManager::#{platform.capitalize}".constantize.project_find_names(project[:name])
    rescue => exception
      PackageManager::Base.project_find_names(project[:name])
    end
  end
end
