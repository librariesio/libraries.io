class Api::StatusController < Api::ApplicationController
  before_action :require_api_key

  def check
    render(
      json: projects.values,
      each_serializer: ProjectStatusSerializer,
      show_score: params[:score],
      show_stats: internal_api_key?,
      project_names: project_names
    )
  end

  private

  def projects
    @projects ||= params[:projects]
      .group_by { |project| project[:platform] }
      .map(&method(:platform_projects))
      .reduce({}, :merge)
  end

  def platform_projects((platform, group))
    ProjectStatusQuery
      .new(platform, group.map { |p| p[:name] })
      .projects_by_name
  end

  def project_names
    projects
      .map { |requested_name, project| [project.name, requested_name] }
      .to_h
  end
end
