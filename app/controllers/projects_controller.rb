class ProjectsController < ApplicationController
  def index
    @licenses = Project.popular_licenses.limit(10)
    @created = Project.order('created_at DESC').limit(4)
    @platforms = Project.popular_platforms(10)
    @languages = GithubRepository.popular_languages.limit(10)
    @contributors = GithubUser.top(30)
    @popular = Project.with_repo.limit(50)
      .order('github_repositories.stargazers_count DESC')
      .to_a.uniq(&:github_repository_id).first(4)
  end

  def show
    @project = Project.platform(params[:platform]).find_by!(name: params[:name])
    @version = @project.versions.find_by!(number: params[:number]) if params[:number].present?
    @versions = @project.versions.order('number DESC').to_a
    if @project.github_repository
      @contributors = @project.github_repository.github_contributions.order('count DESC').includes(:github_user).limit(42)
      @related = @project.github_repository.projects.reject{ |p| p.id == @project.id }
    end
  end
end
