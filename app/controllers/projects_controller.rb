class ProjectsController < ApplicationController
  def index
    @licenses = Project.popular_licenses.limit(10)
    @created = Project.order('created_at DESC').limit(4)
    @platforms = Project.popular_platforms(10)
    @languages = GithubRepository.popular_languages.limit(10)
    @contributors = GithubUser.top(24)
    @popular = Project.with_repo.limit(30)
      .order('github_repositories.stargazers_count DESC')
      .to_a.uniq(&:github_repository_id).first(4)
  end

  def search
    scope = Project.search(params[:q])
    scope = scope.platform(params[:platform]) if params[:platform].present?
    scope = scope.license(params[:license]) if params[:license].present?

    @projects = scope.paginate(page: params[:page])
  end

  def show
    @project = Project.platform(params[:platform]).find_by!(name: params[:name])
    @versions = @project.versions.order('number DESC').to_a
    if @project.github_repository
      @contributors = @project.github_repository.github_contributions.includes(:github_user).limit(42)
      @related = @project.github_repository.projects.reject{ |p| p.id == @project.id }
    end
  end

  def legacy
    @project = Project.find params[:id]
    redirect_to project_path(@project.to_param), :status => :moved_permanently
  end
end
