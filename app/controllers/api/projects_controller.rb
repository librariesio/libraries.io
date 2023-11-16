# frozen_string_literal: true

class Api::ProjectsController < Api::ApplicationController
  before_action :find_project, except: %i[searchcode dependencies dependencies_bulk updated]

  def show
    render(json: @project, show_updated_at: internal_api_key?)
  end

  def sourcerank
    render json: @project.source_rank_breakdown
  end

  def dependents
    render json: { message: "Disabled for performance reasons" }

    #    dependents = @project.dependent_projects
    #
    #    if params[:subset] == "name_only"
    #      render json: paginate(dependents).order(name: :asc).pluck(:name).map { |n| { name: n } }
    #    else
    #      dependents = paginate(dependents).includes(:versions, :repository)
    #      render json: dependents
    #    end
  end

  def dependent_repositories
    paginate json: @project.dependent_repositories
  end

  # we have an arbitrary limit on this to prevent pathology, since there's no pagination.
  # can be pretty high since we're returning only a few fields per row.
  MAX_UPDATED_PROJECTS = 5000

  # returns any updated projects in a time window, the caller can
  # then decide which ones it needs to refetch.
  def updated
    # there's no ActionController::Forbidden
    raise ActionController::BadRequest unless internal_api_key?

    start = DateTime.iso8601(params.require(:start_time))
    stop = if params[:end_time].nil?
             DateTime.current
           else
             DateTime.iso8601(params.require(:end_time))
           end

    results = Project.visible.updated_within(start, stop).limit(MAX_UPDATED_PROJECTS + 1).pluck(:platform, :name, :updated_at)
    deleted_results = DeletedProject.updated_within(start, stop).limit(MAX_UPDATED_PROJECTS + 1).pluck(:digest, :updated_at)

    # seems better to be loud than to just truncate?
    raise ActionController::BadRequest, "query matches too many records" if results.length > MAX_UPDATED_PROJECTS || deleted_results.length > MAX_UPDATED_PROJECTS

    reply = {}

    reply[:updated] = results.map do |platform, name, updated_at|
      {
        platform: platform,
        name: name,
        updated_at: updated_at,
      }
    end

    reply[:deleted] = deleted_results.map do |digest, updated_at|
      {
        digest: digest,
        updated_at: updated_at,
      }
    end

    render json: reply
  end

  def dependencies
    @subset = params.fetch(:subset, "default")

    @project = Project.find_best!(params[:platform], params[:name], %i[repository versions])
    @version = @project.find_version!(params[:number])
    # render app/views/api/projects/dependencies.json.jb
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
    deps = version.dependencies.includes(:project)
    # nil means that we haven't fetched the deps yet, so check back later.
    project_json[:dependencies] = deps.empty? ? nil : map_dependencies(deps)

    project_json
  end
end
