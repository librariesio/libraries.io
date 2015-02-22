class ProjectsController < ApplicationController
  def index
    @licenses = Project.popular_licenses.first(10)
    @created = Project.order('created_at DESC').limit(5).includes(:versions, :github_repository)
    @updated = Project.order('updated_at DESC').limit(5).includes(:versions, :github_repository)
    @platforms = Project.popular_platforms.first(10)
    @languages = Project.popular_languages.first(10)
    @popular = Project.popular.first(5)
  end

  def show
    find_project
    @versions = @project.versions.to_a.sort
    if params[:number].present?
      @version = @project.versions.find { |v| v.number == params[:number] }
      raise ActiveRecord::RecordNotFound if @version.nil?
    end
    @dependencies = (@versions.any? ? (@version || @versions.first).dependencies.order('project_name ASC') : [])
    @dependents = @project.dependent_projects
    @github_repository = @project.github_repository
    @related = @project.mlt
    @contributors = @project.github_contributions.order('count DESC').limit(20).includes(:github_user)
  end

  def find_project
    @project = Project.platform(params[:platform]).where('lower(name) = ?', params[:name].downcase).includes({:versions => :dependencies}, {:github_repository => :readme}).first
    raise ActiveRecord::RecordNotFound if @project.nil?
    redirect_to project_path(@project.to_param), :status => :moved_permanently if params[:platform] != params[:platform].downcase || params[:name] != @project.name
  end
end
