class Api::ProjectsController < Api::ApplicationController
  def show
    find_project
    render json: @project.as_json(:include => [:versions, :github_repository])
  end

  def list
    names = Array(params[:names])
    @projects = Project.platform(params[:platform]).where(name: names).includes(:versions, :github_repository)
    render json: @projects
  end

  def searchcode
    render json: Project.where('updated_at > ?', 1.day.ago).pluck(:repository_url).compact.reject(&:blank?)
  end

  private

  def find_project
    @project = Project.platform(params[:platform]).where('lower(name) = ?', params[:name].downcase).includes(:versions, :github_repository).first
    raise ActiveRecord::RecordNotFound if @project.nil?
    redirect_to project_path(@project.to_param), :status => :moved_permanently if params[:platform] != params[:platform].downcase || params[:name] != @project.name
    @color = @project.color
  end
end
