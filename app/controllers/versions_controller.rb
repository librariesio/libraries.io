class VersionsController < ApplicationController
  def show
    @project = Project.platform(params[:platform]).find_by(name: params[:name])
    @version = @project.versions.find_by!(number: params[:number])
    @versions = @project.versions.order('number DESC').to_a
    if @project.github_repository
      @contributors = @project.github_repository.github_contributions.includes(:github_user).limit(10)
    end
    render template: 'projects/show'
  end

  def legacy
    @project = Project.find params[:project_id]
    @version = @project.versions.find_by!(number: params[:id])
    redirect_to version_path(@version.to_param), :status => :moved_permanently
  end
end
