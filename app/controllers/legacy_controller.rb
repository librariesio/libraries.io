class LegacyController < ApplicationController
  newrelic_ignore

  def project
    @project = Project.find params[:id]
    redirect_to project_path(@project.to_param), :status => :moved_permanently
  end

  def platform
    find_platform
    redirect_to platform_path(@platform_name.downcase), :status => :moved_permanently
  end

  def version
    @project = Project.find params[:project_id]
    @version = @project.versions.find_by!(number: params[:id])
    redirect_to version_path(@version.to_param), :status => :moved_permanently
  end

  def user
    @user = GithubUser.find(params[:id])
    redirect_to user_path(@user), :status => :moved_permanently
  end
end
