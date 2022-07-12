# frozen_string_literal: true
class Admin::ProjectsController < Admin::ApplicationController
  def show
    @project = Project.find(params[:id])
  end

  def update
    @project = Project.find(params[:id])
    # set the flag saying this license was set by admins if there is a value in the form and it is different than what is currently saved
    update_params = project_params
    update_params = update_params.merge(normalized_licenses: Array(update_params[:normalized_licenses])) # convert selected license to an array for normalized_licenses
    update_params = update_params.merge(license_set_by_admin: true) if project_params[:normalized_licenses].present? && project_params[:normalized_licenses] != @project.normalized_licenses
    update_params = update_params.merge(repository_url_set_by_admin: true) if project_params[:repository_url].present? && project_params[:repository_url] != @project.repository_url
    if @project.update(update_params)
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

  def destroy
    @project = Project.find(params[:id])
    @project.destroy
    redirect_to admin_stats_path, notice: 'Project deleted'
  end

  private

  def project_params
    params.require(:project).permit(:repository_url, :normalized_licenses, :status)
  end

  def search(query)
    @search = Project.search(query, filters: {
      platform: params[:platform]
    }, sort: params[:sort], order: params[:order])

    @projects = @search.records.where("status IS ? OR status = ''", nil).order('projects.rank DESC NULLS LAST, name DESC').paginate(page: params[:page])
  end
end
