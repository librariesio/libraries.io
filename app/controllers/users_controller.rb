class UsersController < ApplicationController
  def show
    find_user
    @repositories = @user.github_repositories.order('stargazers_count DESC').limit(10)
    @contributions = @user.github_contributions.with_repo
                          .joins(:github_repository)
                          .where('github_repositories.owner_id != ?', @user.github_id.to_s)
                          .includes(:github_repository)
                          .order('count DESC').limit(10)
  end

  def repositories
    find_user
    @repositories = @user.github_repositories.order('stargazers_count DESC').paginate(page: params[:page])
  end

  def contributions
    find_user
    @contributions = @user.github_contributions.with_repo
                          .joins(:github_repository)
                          .where('github_repositories.owner_id != ?', @user.github_id.to_s)
                          .includes(:github_repository)
                          .order('count DESC').paginate(page: params[:page])
  end

  private

  def find_user
    @user = GithubUser.where("lower(login) = ?", params[:login].downcase).first
    raise ActiveRecord::RecordNotFound if @user.nil?
  end
end
