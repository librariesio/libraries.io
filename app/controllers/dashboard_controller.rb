class DashboardController < ApplicationController
  before_action :ensure_logged_in

  def index
    @repos = current_user.github_repositories
  end

  def watch
    github_repository = GithubRepository.find(params[:github_repository_id])
    github_repository.create_webhook(current_user.token)
    github_repository.download_manifests(current_user.token)
    # subscribe user to repos deps
    redirect_to dashboard_path
  end

  def unwatch
    # unsubscribe user from repos deps
    redirect_to dashboard_path
  end
end
