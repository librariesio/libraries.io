class GithubRepositoriesController < ApplicationController
  def show
    @github_repository = GithubRepository.find_by_full_name([params[:owner], params[:name]].join('/'))
    raise ActiveRecord::RecordNotFound if @github_repository.nil?
    @contributors = @github_repository.github_contributions.order('count DESC').limit(20).includes(:github_user)
    @projects = @github_repository.projects.includes(:versions)
  end
end
