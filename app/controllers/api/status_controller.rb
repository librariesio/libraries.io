class Api::StatusController < Api::ApplicationController
  before_action :require_api_key

  def check
    @projects = params[:projects].map{|project| Project.platform(project[:platform]).includes(:github_repository, :versions).find_by_name(project[:name]) }.compact

    render json: @projects.as_json(only: Project::API_FIELDS, methods: [:package_manager_url, :stars, :forks, :keywords], include: {versions: {only: [:number, :published_at]} })
  end
end
