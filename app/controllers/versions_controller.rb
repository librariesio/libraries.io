class VersionsController < ApplicationController
  def legacy
    @project = Project.find params[:project_id]
    @version = @project.versions.find_by!(number: params[:id])
    redirect_to version_path(@version.to_param), :status => :moved_permanently
  end
end
