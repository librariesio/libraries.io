class Api::GithubUsersController < Api::ApplicationController
  before_action :check_api_key, :find_user

  def show
    render json: @github_user.as_json
  end

  def repositories
    @repositories = @github_user.github_repositories.open_source.source.order('stargazers_count DESC')

    render json: @repositories.paginate(page: page_number, per_page: per_page_number)
  end

  def projects
    scope = @github_user.projects.joins(:github_repository).includes(:versions).order('projects.rank DESC, projects.created_at DESC')
    scope = scope.keywords(params[:keywords].split(',')) if params[:keywords].present?
    @projects = scope.paginate(page: page_number)

    render json: @projects.paginate(page: page_number, per_page: per_page_number)
  end

  private

  def find_user
    @github_user = GithubUser.visible.where("lower(login) = ?", params[:login].downcase).first
    @github_user = GithubOrganisation.visible.where("lower(login) = ?", params[:login].downcase).first if @github_user.nil?
    raise ActiveRecord::RecordNotFound if @github_user.nil?
  end
end
