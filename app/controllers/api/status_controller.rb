class Api::StatusController < Api::ApplicationController
  before_action :require_api_key

  def check
    render(
      json: projects,
      each_serializer: ProjectStatusSerializer,
      show_score: params[:score],
      show_stats: internal_api_key?,
      project_names: project_names
    )
  end

  private

  def project_status_queries
    @project_status_queries ||= params[:projects]
      .group_by { |project| project[:platform] }
      .map { |platform, group| ProjectStatusQuery.new(platform, group.map { |p| p[:name] }) }
  end

  def projects
    project_status_queries
      .map(&:projects_by_name)
      .flat_map(&:values)
  end

  def project_names
    project_status_queries.each_with_object({}) do |psq, result|
      psq.projects_by_name.each do |requested_name, project|
        result[[project.platform, project.name]] = requested_name
      end
    end
  end
end
