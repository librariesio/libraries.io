class ProjectsController < ApplicationController
  def index
    @licenses = Project.popular_licenses(10)
    @updated = Project.order('updated_at DESC').limit(4)
    @platforms = Project.popular_platforms(10)
  end

  def search
    scope = Project.search(params[:q])
    scope = scope.platform(params[:platform]) if params[:platform].present?
    scope = scope.license(params[:license]) if params[:license].present?

    @projects = scope.paginate(page: params[:page])
  end

  def show
    @project = Project.find params[:id]
    @versions = @project.versions.order('number DESC').to_a
    if @project.github_repository
      @contributors = @project.github_repository.github_contributions.includes(:github_user).limit(10)
    end
  end
end
