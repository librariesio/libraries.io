class UsersController < ApplicationController
  def show
    find_user
    @repositories = @user.github_repositories.open_source.source.order('stargazers_count DESC').limit(6)
    @favourite_projects = @user.top_favourite_projects.limit(6)
    @projects = @user.projects.joins(:github_repository).includes(:versions).order('projects.rank DESC, projects.created_at DESC').limit(6)
    if @user.org?
      @contributions = []
    else
      @contributions = @user.github_contributions.with_repo
                          .joins(:github_repository)
                          .where('github_repositories.owner_id != ?', @user.github_id.to_s)
                          .where('github_repositories.fork = ?', false)
                          .where('github_repositories.private = ?', false)
                          .includes(:github_repository)
                          .order('count DESC').limit(6)
    end
  end

  def repositories
    find_user
    @repositories = @user.github_repositories.open_source.source.order('stargazers_count DESC').paginate(page: page_number)
  end

  def contributions
    find_user
    @contributions = @user.github_contributions.with_repo
                          .joins(:github_repository)
                          .where('github_repositories.owner_id != ?', @user.github_id.to_s)
                          .where('github_repositories.fork = ?', false)
                          .where('github_repositories.private = ?', false)
                          .includes(:github_repository)
                          .order('count DESC').paginate(page: page_number)
  end

  def projects
    find_user
    order = params[:sort] == "contributions" ? "github_repositories.github_contributions_count ASC, projects.rank DESC, projects.created_at DESC" : 'projects.rank DESC, projects.created_at DESC'
    @projects = @user.projects.joins(:github_repository).includes(:github_repository, :versions).order(order).paginate(page: page_number)
  end

  private

  def find_user
    @user = GithubUser.visible.where("lower(login) = ?", params[:login].downcase).first
    @user = GithubOrganisation.visible.where("lower(login) = ?", params[:login].downcase).first if @user.nil?
    raise ActiveRecord::RecordNotFound if @user.nil?
    redirect_to user_path(@user), :status => :moved_permanently if params[:login] != @user.login
  end
end
