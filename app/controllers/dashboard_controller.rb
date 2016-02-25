class DashboardController < ApplicationController
  before_action :ensure_logged_in, except: :home

  def index
    @orgs = current_user.adminable_github_orgs.order(:login)
    @org = @orgs.find{|org| org.login == params[:org] }
    @repos = current_user.adminable_github_repositories.order('fork ASC, pushed_at DESC').paginate(per_page: 30, page: params[:page])
    if @org
      @repos = @repos.from_org(@org)
    else
      @repos =  @repos.from_org(nil)
    end
  end

  def home
    respond_to do |format|
      format.atom do
        if params[:api_key].present? && api_key = ApiKey.active.find_by_access_token(params[:api_key])
          @user = api_key.user
          @versions = @user.all_subscribed_versions.where.not(project_id: @user.muted_project_ids).where.not(published_at: nil).newest_first.includes(:project).paginate(per_page: 100, page: params[:page])
        else
          raise ActiveRecord::RecordNotFound
        end
      end
      format.html do
        redirect_to root_path
      end
    end
  end

  def muted
    @projects = current_user.muted_projects.paginate(page: params[:page])
  end

  def sync
    current_user.update_column(:currently_syncing, true)
    current_user.update_repo_permissions_async
    redirect_to_back_or_default repositories_path
  end

  def watch
    github_repository = GithubRepository.find(params[:github_repository_id])
    if current_user.can_watch?(github_repository)
      current_user.subscribe_to_repo(github_repository)
      redirect_to_back_or_default repositories_path
    else
      redirect_to pricing_path, notice: 'You need to upgrade your plan to track more repositories'
    end
  end

  def unwatch
    github_repository = GithubRepository.find(params[:github_repository_id])
    current_user.unsubscribe_from_repo(github_repository)
    redirect_to_back_or_default repositories_path
  end

  private

  def repository_subscription_params
    params.require(:repository_subscription).permit(:include_prerelease)
  end
end
