class DashboardController < ApplicationController
  before_action :ensure_logged_in

  def index
    @repos = current_user.github_repositories.order(:full_name)
  end

  def watch
    github_repository = GithubRepository.find(params[:github_repository_id])
    github_repository.create_webhook(current_user.token)
    current_user.subscribe_to_repo(github_repository)
    redirect_to dashboard_path
  end

  def unwatch
    github_repository = GithubRepository.find(params[:github_repository_id])
    current_user.unsubscribe_from_repo(github_repository)
    redirect_to dashboard_path
  end
end
