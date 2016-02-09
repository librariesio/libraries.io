class Admin::GithubRepositoriesController < Admin::ApplicationController
  def show
    @github_repository = GithubRepository.find(params[:id])
  end

  def update
    @github_repository = GithubRepository.find(params[:id])
    if @github_repository.update_attributes(github_repository_params)
      @github_repository.update_all_info_async
      redirect_to github_repository_path(@github_repository.owner_name, @github_repository.project_name)
    else
      redirect_to admin_github_repository_path(@github_repository.id)
    end
  end

  def index
    @github_repositories = GithubRepository.without_license.with_projects.order("COUNT(projects.id) DESC").group("github_repositories.id").paginate(page: params[:page])
  end

  def mit
    @github_repositories = GithubRepository.with_projects.language('Go').without_license.group('github_repositories.id').includes(:readme).order('github_repositories.stargazers_count DESC').paginate(page: params[:page], per_page: 100)
  end

  private

  def github_repository_params
    params.require(:github_repository).permit(:license)
  end
end
