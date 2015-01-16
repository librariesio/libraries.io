class VersionsController < ApplicationController
  def show
    @project = Project.find params[:project_id]
    @version = @project.versions.find_by!(number: params[:id])
    @versions = @project.versions.order('number DESC').to_a
    render template: 'projects/show'
  end
end
