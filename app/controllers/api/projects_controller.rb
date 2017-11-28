class Api::ProjectsController < Api::ApplicationController
  before_action :find_project, except: :searchcode

  def show
    render json: @project
  end

  def dependents
    dependents = paginate(@project.dependent_projects).includes(:versions, :repository)
    render json: dependents
  end

  def dependent_repositories
    paginate json: @project.dependent_repositories
  end

  def searchcode
    render json: Project.where('updated_at > ?', 1.day.ago).order(:repository_url).pluck(:repository_url).visible.compact.reject(&:blank?)
  end

  def dependencies
    version = if params[:version] == 'latest'
                @project.versions.sort.first
              else
                @project.versions.find_by_number(params[:version])
              end

    raise ActiveRecord::RecordNotFound if version.nil?



    project_json = ProjectSerializer.new(@project).as_json
    project_json[:dependencies] = map_dependencies(version.dependencies || [])

    render json: project_json
  end

  def contributors
    paginate json: @project.contributors
  end
end
