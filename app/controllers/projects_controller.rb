class ProjectsController < ApplicationController
  def index
    scope = Project.order('created_at DESC')
    scope = scope.platform(params[:platform]) if params[:platform].present?
    scope = scope.license(params[:license]) if params[:license].present?

    @projects = scope.paginate(page: params[:page])
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
      @contributors = @project.github_repository.github_contributions.includes(:github_user)
    end
  end
end
