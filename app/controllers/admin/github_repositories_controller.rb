class Admin::GithubRepositoriesController < Admin::ApplicationController
  def show
    @github_repository = GithubRepository.find(params[:id])
  end

  def update
    @github_repository = GithubRepository.find(params[:id])
    if @github_repository.update_attributes(github_repository_params)
      redirect_to github_repository_path(@github_repository.owner_name, @github_repository.project_name)
    else
      redirect_to admin_github_repository_path(@github_repository.id)
    end
  end

  def index
    @github_repositories = GithubRepository.where("github_repositories.license IS ? OR github_repositories.license = ''", nil).with_projects.order('stargazers_count DESC').paginate(page: params[:page])
  end

  private

  def github_repository_params
    params.require(:github_repository).permit(:license)
  end
end
