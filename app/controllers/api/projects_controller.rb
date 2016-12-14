class Api::ProjectsController < Api::ApplicationController
  before_action :find_project, except: :searchcode

  def show
    render json: project_json_response(@project)
  end

  def dependents
    dependents = paginate(@project.dependent_projects).includes(:versions, :github_repository)
    render json: project_json_response(dependents)
  end

  def dependent_repositories
    paginate json: @project.dependent_repositories.as_json(except: [:id, :github_organisation_id, :owner_id])
  end

  def searchcode
    render json: Project.where('updated_at > ?', 1.day.ago).pluck(:repository_url).compact.reject(&:blank?)
  end

  def dependencies
    version = if params[:version] == 'latest'
                @project.versions.first
              else
                @project.versions.find_by_number(params[:version])
              end

    raise ActiveRecord::RecordNotFound if version.nil?

    project_json = project_json_response(@project)
    project_json[:dependencies] = map_dependencies(version.dependencies || [])

    render json: project_json
  end

  private

  def find_project
    @project = Project.platform(params[:platform]).where('lower(name) = ?', params[:name].downcase).includes(:versions, :github_repository).first
    raise ActiveRecord::RecordNotFound if @project.nil?
  end
end
