class Admin::ProjectsController < Admin::ApplicationController
  def show
    @project = Project.find(params[:id])
  end

  def update
    @project = Project.find(params[:id])
    if @project.update_attributes(project_params)
      @project.normalize_licenses
      @project.update_github_repo_async
      redirect_to project_path(@project.to_param)
    else
      redirect_to admin_project_path(@project.id)
    end
  end

  def index
    scope = Project.without_repository_url.without_repo.most_dependents.where('latest_release_published_at > ?', 2.years.ago)
    if params[:platform].present?
      @platform = Project.platform(params[:platform].downcase).first.try(:platform)
      raise ActiveRecord::RecordNotFound if @platform.nil?
      scope = scope.platform(@platform)
    end

    @platforms = Project.without_repository_url.most_dependents.pluck('platform').compact.uniq
    @projects = scope.paginate(page: params[:page])
  end

  private

  def project_params
    params.require(:project).permit(:repository_url, :licenses)
  end
end
