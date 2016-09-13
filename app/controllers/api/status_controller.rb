class Api::StatusController < Api::ApplicationController
  before_action :require_api_key

  def check
    if params[:projects].any?
      @projects = params[:projects].group_by{|project| project[:platform] }.map do |platform, projects|
        projects.map{|project| project[:name] }.each_slice(20).map do |names_slice|
          Project.platform(platform).where(name: names_slice).includes(:github_repository, :versions)
        end
      end.flatten.compact
    else
      @projects = []
    end
    render json: @projects.as_json(only: Project::API_FIELDS, methods: [:package_manager_url, :stars, :forks, :keywords], include: {versions: {only: [:number, :published_at]} })
  end
end
