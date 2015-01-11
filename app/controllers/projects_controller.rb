class ProjectsController < ApplicationController
  def index
    @projects = Project.order('created_at DESC').limit(100)
  end

  def show
    @project = Project.find params[:id]
  end
end
