class DashboardController < ApplicationController
  before_action :ensure_logged_in

  def index
    @orgs = current_user.adminable_github_orgs.order(:login)
    @org = @orgs.find{|org| org.login == params[:org] }
    @repos = current_user.adminable_github_repositories.order('pushed_at DESC').paginate(per_page: 15, page: params[:page])
    @repos = @repos.from_org(@org.try(:id)) if params[:org].present?
  end

  def watch
    github_repository = GithubRepository.find(params[:github_repository_id])
    current_user.subscribe_to_repo(github_repository)
    redirect_to dashboard_path
  end

  def unwatch
    github_repository = GithubRepository.find(params[:github_repository_id])
    current_user.unsubscribe_from_repo(github_repository)
    redirect_to dashboard_path
  end
end
