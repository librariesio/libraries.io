class UsersController < ApplicationController
  before_action :find_user

  def show
    @repositories = @user.github_repositories.open_source.source.order('stargazers_count DESC').limit(6)
    @favourite_projects = @user.top_favourite_projects.limit(6)
    @projects = @user.projects.joins(:github_repository).includes(:versions).order('projects.rank DESC, projects.created_at DESC').limit(6)
    if @user.org?
      @contributions = []
    else
      @contributions = find_contributions.limit(6)
    end
  end

  def issues
    @repo_ids = @user.github_repositories.open_source.source.pluck(:id)
    search_issues(repo_ids: @repo_ids)
  end

  def dependency_issues
    @repo_ids = @user.all_dependent_repos.open_source.pluck(:id) - @user.github_repositories.pluck(:id)
    search_issues(repo_ids: @repo_ids)
  end

  def repositories
    @repositories = @user.github_repositories.open_source.source.order('stargazers_count DESC').paginate(page: page_number)
  end

  def contributions
    @contributions = find_contributions.paginate(page: page_number)
  end

  def projects
    order = params[:sort] == "contributions" ? "github_repositories.github_contributions_count ASC, projects.rank DESC, projects.created_at DESC" : 'projects.rank DESC, projects.created_at DESC'
    @projects = @user.projects.joins(:github_repository).includes(:github_repository).order(order).paginate(page: page_number)
  end

  def contributors
    @contributors = @user.contributors.paginate(page: params[:page])
  end

  private

  def find_user
    @user = GithubUser.visible.where("lower(login) = ?", params[:login].downcase).first
    @user = GithubOrganisation.visible.where("lower(login) = ?", params[:login].downcase).first if @user.nil?
    raise ActiveRecord::RecordNotFound if @user.nil?
    redirect_to user_path(@user), :status => :moved_permanently if params[:login] != @user.login
  end

  def find_contributions
    @user.github_contributions.with_repo
                              .joins(:github_repository)
                              .where('github_repositories.owner_id != ?', @user.github_id.to_s)
                              .where('github_repositories.fork = ?', false)
                              .where('github_repositories.private = ?', false)
                              .includes(:github_repository)
                              .order('count DESC')
  end

  def current_language
    params[:language] if params[:language].present?
  end

  def current_license
    params[:license] if params[:license].present?
  end
end
