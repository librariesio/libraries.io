class ProjectsController < ApplicationController
  def index
    @licenses = Project.popular_licenses.first(10)
    @created = Project.order('created_at DESC').limit(5).includes(:versions)
    @platforms = Project.popular_platforms.first(10)
    @languages = Project.popular_languages.first(10)
    @contributors = GithubUser.top(20)
    @popular = Project.popular.first(5)
  end

  def show
    find_project
    @version = @project.versions.find_by!(number: params[:number]) if params[:number].present?
    @versions = @project.versions.to_a.sort
    @dependencies = (@versions.any? ? (@version || @versions.first).dependencies : [])
    @related = @project.mlt
    @contributors = @project.github_repository.github_contributions.order('count DESC').includes(:github_user).limit(20) if @project.github_repository
  end

  def find_project
    @project = Project.platform(params[:platform]).where('lower(name) = ?', params[:name].downcase).includes({:versions => :dependencies}, {:github_repository => {:github_contributions => :github_user}}).first
    raise ActiveRecord::RecordNotFound if @project.nil?
    redirect_to project_path(@project.to_param), :status => :moved_permanently if params[:platform] != params[:platform].downcase || params[:name] != @project.name
  end
end
