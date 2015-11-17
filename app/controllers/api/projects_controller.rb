class Api::ProjectsController < Api::ApplicationController
  before_action :find_project, :check_api_key, except: :searchcode

  def show
    render json: @project.as_json(only: [:name, :platform, :description, :language, :homepage, :repository_url,  :normalized_licenses], include: {versions: {only: [:number, :published_at]} })
  end

  def dependents
    render json: @project.dependent_projects.paginate(page: params[:page]).as_json(only: [:name, :platform, :description, :language, :homepage, :repository_url,  :normalized_licenses], include: {versions: {only: [:number, :published_at]} })
  end

  def dependent_repositories
    render json: @project.dependent_repositories.paginate(page: params[:page]).as_json(except: [:id, :github_organisation_id, :owner_id])
  end

  def searchcode
    render json: Project.where('updated_at > ?', 1.day.ago).pluck(:repository_url).compact.reject(&:blank?)
  end

  private

  def find_project
    @project = Project.platform(params[:platform]).where('lower(name) = ?', params[:name].downcase).includes(:versions, :github_repository).first
    raise ActiveRecord::RecordNotFound if @project.nil?
  end
end
