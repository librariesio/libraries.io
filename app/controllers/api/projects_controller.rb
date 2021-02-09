class Api::ProjectsController < Api::ApplicationController
  before_action :find_project, except: [:searchcode, :dependencies, :dependencies_bulk, :updated]

  def show
    render(json: @project, show_updated_at: internal_api_key?)
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
    render json: Project.visible.where('updated_at > ?', 1.day.ago).order(:repository_url).pluck(:repository_url).compact.reject(&:blank?)
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
    raise ActionController::BadRequest.new("query matches too many records") if results.length > MAX_UPDATED_PROJECTS || deleted_results.length > MAX_UPDATED_PROJECTS

    reply = {}

    reply[:updated] = results.map do |platform, name, updated_at|
      {
        platform: platform,
        name: name,
        updated_at: updated_at
      }
    end

    reply[:deleted] = deleted_results.map do |digest, updated_at|
      {
        digest: digest,
        updated_at: updated_at
      }
    end

    render json: reply
  end

  def dependencies
    subset = params.fetch(:subset, "default")

    if params[:v2] == "true"
      @project = Project.find_best!(params[:platform], params[:name], [:repository, :versions])
      @version = @project.find_version!(params[:version])
      @subset = subset
      # render
    else
      project_json = find_project_as_json_with_dependencies!(params[:platform], params[:name], params[:version], subset)
      render json: project_json
    end
  end

  def dependencies_bulk
    subset = params.fetch(:subset, "default")

    results = []
    if params[:projects].any?
      params[:projects].each do |project_param|
        platform = project_param[:platform]
        name = project_param[:name]
        version_string = project_param.fetch(:version, 'latest')
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
                           dependencies_for_version: version_string
                         }
                       })
        end
      end
    end

    render json: results
  end

  def contributors
    paginate json: @project.contributors.order('count DESC')
  end

  private

  def find_project_as_json_with_dependencies!(platform, name, version_name, subset)
    serializer, includes = case subset
              when "default"
                [ProjectSerializer, [:repository, :versions]]
              when "minimum"
                [MinimumProjectSerializer, []]
              else
                raise ActionController::BadRequest.new("Unsupported subset")
              end

    project = Project.find_best!(platform, name, includes)
    version = project.find_version!(version_name)

    project_json = serializer.new(project).as_json
    project_json[:dependencies_for_version] = version.number
    project_json[:dependencies] = map_dependencies(version.dependencies.includes(:project) || [])

    project_json
  end

end
