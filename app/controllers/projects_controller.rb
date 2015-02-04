class ProjectsController < ApplicationController
  def index
    @licenses = Project.popular_licenses.limit(10)
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
    @project = Project.platform(params[:platform]).find_by!(name: params[:name])
    @versions = @project.versions.order('number DESC').to_a
    if @project.github_repository
      @contributors = @project.github_repository.github_contributions.includes(:github_user).limit(10)
      @related = @project.github_repository.projects.reject{ |p| p.id == @project.id }
    end
  end

  def legacy
    @project = Project.find params[:id]
    redirect_to project_path(@project.to_param), :status => :moved_permanently
  end
end
