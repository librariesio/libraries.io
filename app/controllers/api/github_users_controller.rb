class Api::GithubUsersController < Api::ApplicationController
  before_action :find_user

  def show
    render json: @github_user
  end

  def repositories
    @repositories = @github_user.repositories.open_source.source.order('stargazers_count DESC')

    paginate json: @repositories
  end

  def projects
    @projects = @github_user.projects.joins(:repository).includes(:versions).order('projects.rank DESC, projects.created_at DESC')
    @projects = @projects.keywords(params[:keywords].split(',')) if params[:keywords].present?

    paginate json: @projects
  end

  private

  def find_user
    @github_user = GithubUser.visible.where("lower(login) = ?", params[:login].downcase).first
    @github_user = GithubOrganisation.visible.where("lower(login) = ?", params[:login].downcase).first if @github_user.nil?
    raise ActiveRecord::RecordNotFound if @github_user.nil?
  end
end
