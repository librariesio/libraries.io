class Api::ProjectsController < Api::ApplicationController
  def show
    @project = Project.platform(params[:platform]).where('lower(name) = ?', params[:name].downcase).includes(:versions, :github_repository).first
    raise ActiveRecord::RecordNotFound if @project.nil?
    render json: @project.as_json(:include => [:versions])
  end

  def list
    names = Array(params[:names])
    @projects = Project.platform(params[:platform]).where(name: names).includes(:versions, :github_repository)
    render json: @projects
  end

  def searchcode
    render json: Project.where('updated_at > ?', 1.day.ago).pluck(:repository_url).compact.reject(&:blank?)
  end
end
