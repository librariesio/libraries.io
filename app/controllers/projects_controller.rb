class ProjectsController < ApplicationController
  def index
    @licenses = Project.popular_licenses.first(10)
    @created = Project.order('created_at DESC').limit(4)
    @platforms = Project.popular_platforms.first(10)
    @languages = Project.popular_languages.first(10)
    @contributors = GithubUser.top(30)
    @popular = Project.popular.first(4)
  end

  def show
    @project = Project.platform(params[:platform]).find_by!(name: params[:name])
    @version = @project.versions.find_by!(number: params[:number]) if params[:number].present?
    @versions = @project.versions.to_a.sort
    if @project.github_repository
      @contributors = @project.github_repository.github_contributions.order('count DESC').includes(:github_user).limit(42)
      @related = @project.github_repository.projects.reject{ |p| p.id == @project.id }
    end
  end
end
