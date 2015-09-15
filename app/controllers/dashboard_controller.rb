class DashboardController < ApplicationController
  before_action :ensure_logged_in

  def index
    @orgs = current_user.adminable_github_orgs.order(:login)
    @org = @orgs.find{|org| org.login == params[:org] }
    @repos = current_user.adminable_github_repositories.order('pushed_at DESC').paginate(per_page: 30, page: params[:page])
    if @org
      @repos = @repos.from_org(@org)
    else
      @repos =  @repos.from_org(nil)
    end
  end

  def sync
    current_user.update_column(:currently_syncing, true)
    current_user.update_repo_permissions
    redirect_to_back_or_default repositories_path
  end

  def watch
    github_repository = GithubRepository.find(params[:github_repository_id])
    current_user.subscribe_to_repo(github_repository)
    redirect_to_back_or_default repositories_path
  end

  def unwatch
    github_repository = GithubRepository.find(params[:github_repository_id])
    current_user.unsubscribe_from_repo(github_repository)
    redirect_to_back_or_default repositories_path
  end
end
