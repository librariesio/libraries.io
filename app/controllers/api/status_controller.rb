class Api::StatusController < Api::ApplicationController
  before_action :require_api_key

  def check
    if params[:projects].any?
      @projects = params[:projects].group_by{|project| project[:platform] }.map do |platform, projects|
        Project.lookup_multiple(platform, projects.map{|project| project[:name] }).records.includes(:github_repository, :versions)
      end.flatten.compact
    else
      @projects = []
    end
    render json: project_json_response(@projects)
  end
end
