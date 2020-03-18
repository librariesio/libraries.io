# frozen_string_literal: true

class Api::ProjectsController < Api::ApplicationController
  before_action :find_project, except: %i[searchcode dependencies dependencies_bulk]

  def show
    render json: @project
  end

  def sourcerank
    render json: @project.source_rank_breakdown
  end

  def dependents
    dependents = paginate(@project.dependent_projects).includes(:versions, :repository)
    render json: dependents
  end

  def dependent_repositories
    paginate json: @project.dependent_repositories
  end

  def searchcode
    render json: Project.visible.where("updated_at > ?", 1.day.ago).order(:repository_url).pluck(:repository_url).compact.reject(&:blank?)
  end

  def dependencies
    subset = params.fetch(:subset, "default")
    project_json = find_project_as_json_with_dependencies!(params[:platform], params[:name], params[:version], subset)

    render json: project_json
  end

  def dependencies_bulk
    subset = params.fetch(:subset, "default")

    results = []
    if params[:projects].any?
      params[:projects].each do |project_param|
        platform = project_param[:platform]
        name = project_param[:name]
        version_string = project_param.fetch(:version, "latest")
        begin
          body = find_project_as_json_with_dependencies!(platform, name, version_string, subset)
          results.push({ status: 200,
                         body: body })
        rescue ActiveRecord::RecordNotFound
          results.push({ status: 404,
                         body: {
                           error: "Error 404, project or project version not found.",
                           platform: platform,
                           name: name,
                           dependencies_for_version: version_string,
                         } })
        end
      end
    end

    render json: results
  end

  def contributors
    paginate json: @project.contributors.order("count DESC")
  end

  private

  def find_project_as_json_with_dependencies!(platform, name, version_name, subset)
    serializer, includes = case subset
                           when "default"
                             [ProjectSerializer, %i[repository versions]]
                           when "minimum"
                             [MinimumProjectSerializer, []]
                           else
                             raise ActionController::BadRequest, "Unsupported subset"
              end

    project = Project.find_best!(platform, name, includes)
    version = project.find_version!(version_name)

    project_json = serializer.new(project).as_json
    project_json[:dependencies_for_version] = version.number
    project_json[:dependencies] = map_dependencies(version.dependencies.includes(:project) || [])

    project_json
  end
end
