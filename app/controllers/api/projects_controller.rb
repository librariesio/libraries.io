class Api::ProjectsController < Api::ApplicationController
  before_action :find_project, :check_api_key, except: :searchcode

  def show
    render json: @project.as_json(only: Project::API_FIELDS, methods: [:package_manager_url, :stars, :forks, :keywords], include: {versions: {only: [:number, :published_at]} })
  end

  def dependents
    @dependents = WillPaginate::Collection.create(page_number, per_page_number, @project.dependents_count) do |pager|
      pager.replace(@project.dependent_projects(page: page_number).includes(:versions, :github_repository))
    end

    render json: @dependents.as_json(only: Project::API_FIELDS, methods: [:package_manager_url, :stars, :forks, :keywords], include: {versions: {only: [:number, :published_at]} })
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

    dependencies = version.dependencies || []

    deps = dependencies.map do |dependency|
      {
        project_name: dependency.project_name,
        name: dependency.project_name,
        platform: dependency.platform,
        requirements: dependency.requirements,
        latest_stable: dependency.try(:project).try(:latest_stable_release_number),
        latest: dependency.try(:project).try(:latest_release_number),
        deprecated: dependency.try(:project).try(:is_deprecated?),
        outdated: dependency.outdated?
      }
    end

    project_json = @project.as_json(only: Project::API_FIELDS, methods: [:package_manager_url, :stars, :forks, :keywords])
    project_json[:dependencies] = deps

    render json: project_json
  end

  private

  def find_project
    @project = Project.platform(params[:platform]).where('lower(name) = ?', params[:name].downcase).includes(:versions, :github_repository).first
    raise ActiveRecord::RecordNotFound if @project.nil?
  end
end
