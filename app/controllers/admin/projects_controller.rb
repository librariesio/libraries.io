class Admin::ProjectsController < Admin::ApplicationController
  def show
    @project = Project.find(params[:id])
  end

  def update
    @project = Project.find(params[:id])
    if @project.update_attributes(project_params)
      @project.normalize_licenses
      @project.update_github_repo_async
      @project.github_repository.try(:update_all_info_async)
      redirect_to project_path(@project.to_param)
    else
      redirect_to admin_project_path(@project.id)
    end
  end

  def index
    scope = Project.maintained.without_repository_url.without_repo.most_dependents.where('latest_release_published_at > ?', 2.years.ago)
    if params[:platform].present?
      @platform = Project.platform(params[:platform].downcase).first.try(:platform)
      raise ActiveRecord::RecordNotFound if @platform.nil?
      scope = scope.platform(@platform)
    end

    @platforms = Project.without_repository_url.most_dependents.pluck('platform').compact.uniq
    @projects = scope.paginate(page: params[:page])
  end

  def deprecated
    @search = Project.search('deprecated', filters: {
      platform: params[:platform]
    }, sort: params[:sort], order: params[:order])

    @projects = @search.records.where("status IS ? OR status = ''", nil).order('projects.rank DESC, name DESC').paginate(page: params[:page])

    # if @projects.empty?
    #   repo_ids = GithubRepository.with_projects.where("github_repositories.description ilike '%deprecated%'").pluck(:id)
    #   @projects = Project.where("status IS ? OR status = ''", nil).where(github_repository_id: repo_ids).order('projects.rank DESC, name DESC').paginate(page: params[:page])
    # end
  end

  def unmaintained
    @search = Project.search('unmaintained', filters: {
      platform: params[:platform]
    }, sort: params[:sort], order: params[:order])

    @projects = @search.records.where("status IS ? OR status = ''", nil).order('projects.rank DESC, name DESC').paginate(page: params[:page])

    # if @projects.empty?
    #   repo_ids = GithubRepository.with_projects.where("github_repositories.description ilike '%maintained%'").pluck(:id)
    #   @projects = Project.where("status IS ? OR status = ''", nil).where(github_repository_id: repo_ids).order('projects.rank DESC, name DESC').paginate(page: params[:page])
    # end
  end

  private

  def project_params
    params.require(:project).permit(:repository_url, :licenses, :status)
  end
end
