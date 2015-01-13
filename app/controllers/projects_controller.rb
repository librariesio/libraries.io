class ProjectsController < ApplicationController
  def index
    scope = Project.order('created_at DESC')
    scope = scope.platform(params[:platform]) if params[:platform].present?
    scope = scope.license(params[:license]) if params[:license].present?

    @projects = scope.limit(30)
  end

  def search
    scope = Project.search(params[:q])
    scope = scope.platform(params[:platform]) if params[:platform].present?
    scope = scope.license(params[:license]) if params[:license].present?

    @projects = scope.limit(30)
  end

  def show
    @project = Project.find params[:id]
  end
end
