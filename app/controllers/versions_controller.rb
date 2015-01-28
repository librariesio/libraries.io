class VersionsController < ApplicationController
  def show
    @project = Project.find params[:project_id]
    @version = @project.versions.find_by!(number: params[:id])
    @versions = @project.versions.order('number DESC').to_a
    if @project.github_repository
      @contributors = @project.github_repository.github_contributions.includes(:github_user).limit(10)
    end
    render template: 'projects/show'
  end
end
