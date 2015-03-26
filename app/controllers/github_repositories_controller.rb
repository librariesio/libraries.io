class GithubRepositoriesController < ApplicationController
  def show
    full_name = [params[:owner], params[:name]].join('/')
    @github_repository = GithubRepository.where('lower(full_name) = ?', full_name.downcase).first
    raise ActiveRecord::RecordNotFound if @github_repository.nil?
    redirect_to github_repository_path(@github_repository.owner_name, @github_repository.project_name), :status => :moved_permanently if full_name != @github_repository.full_name
    @contributors = @github_repository.github_contributions.order('count DESC').limit(20).includes(:github_user)
    @projects = @github_repository.projects
    @color = @github_repository.color
  end
end
