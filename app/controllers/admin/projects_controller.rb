class Admin::ProjectsController < Admin::ApplicationController
  def show
    @project = Project.find(params[:id])
  end

  def update
    @project = Project.find(params[:id])
    if @project.update_attributes(project_params)
      @project.normalize_licenses
      @project.update_repository_async
      @project.async_sync
      @project.repository.try(:update_all_info_async)
      redirect_to project_path(@project.to_param)
    else
      redirect_to admin_project_path(@project.id)
    end
  end

  def index
    scope = Project.maintained.without_repository_url.without_repo.most_dependents.where('latest_release_published_at > ?', 2.years.ago)
    scope = platform_scope(scope)

    @platforms = Project.without_repository_url.most_dependents.pluck('platform').compact.uniq
    @projects = scope.paginate(page: params[:page])
  end

  def deprecated
    search('deprecated')
  end

  def unmaintained
    search('unmaintained')
  end

  private

  def project_params
    params.require(:project).permit(:repository_url, :licenses, :status)
  end

  def search(query)
    @search = Project.search(query, filters: {
      platform: params[:platform]
    }, sort: params[:sort], order: params[:order])

    @projects = @search.records.where("status IS ? OR status = ''", nil).order('projects.rank DESC NULLS LAST, name DESC').paginate(page: params[:page])
  end
end
