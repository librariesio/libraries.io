class UsersController < ApplicationController
  before_action :find_user

  def show
    @repositories = @user.repositories.open_source.source.order('stargazers_count DESC').limit(6)
    @favourite_projects = @user.top_favourite_projects.limit(6)
    @projects = @user.projects.joins(:repository).includes(:versions).order('projects.rank DESC, projects.created_at DESC').limit(6)
    if @user.org?
      @contributions = []
    else
      @contributions = find_contributions.limit(6)
    end
  end

  def issues
    @repo_ids = @user.repositories.open_source.source.pluck(:id)
    search_issues(repo_ids: @repo_ids)
  end

  def dependency_issues
    @repo_ids = @user.all_dependent_repos.open_source.pluck(:id) - @user.repositories.pluck(:id)
    search_issues(repo_ids: @repo_ids)
  end

  def repositories
    @repositories = @user.repositories.open_source.source.order('stargazers_count DESC').paginate(page: page_number)
  end

  def contributions
    @contributions = find_contributions.paginate(page: page_number)
  end

  def projects
    order = params[:sort] == "contributions" ? "repositories.github_contributions_count ASC, projects.rank DESC, projects.created_at DESC" : 'projects.rank DESC, projects.created_at DESC'
    @projects = @user.projects.joins(:repository).includes(:repository).order(order).paginate(page: page_number)
  end

  def contributors
    @contributors = @user.contributors.paginate(page: params[:page])
  end

  private

  def find_user
    @user = GithubUser.visible.where("lower(login) = ?", params[:login].downcase).first
    @user = GithubOrganisation.visible.where("lower(login) = ?", params[:login].downcase).first if @user.nil?
    raise ActiveRecord::RecordNotFound if @user.nil?
    redirect_to url_for(login: @user.login), :status => :moved_permanently if params[:login] != @user.login
  end

  def find_contributions
    @user.github_contributions.with_repo
                              .joins(:repository)
                              .where('repositories.owner_id != ?', @user.github_id.to_s)
                              .where('repositories.fork = ?', false)
                              .where('repositories.private = ?', false)
                              .includes(:repository)
                              .order('count DESC')
  end

  def current_language
    params[:language] if params[:language].present?
  end

  def current_license
    params[:license] if params[:license].present?
  end
end
