# frozen_string_literal: true
class Api::RepositoryUsersController < Api::ApplicationController
  before_action :find_user

  def show
    render json: @repository_user
  end

  def repositories
    paginate json: @repository_user.repositories.open_source.source.order('stargazers_count DESC, rank DESC NULLS LAST')
  end

  def projects
    @projects = @repository_user.projects.visible.joins(:repository).includes(:versions).order('projects.rank DESC NULLS LAST, projects.created_at DESC')
    @projects = @projects.keywords(params[:keywords].split(',')) if params[:keywords].present?

    paginate json: @projects
  end

  def repository_contributions
    paginate json: @repository_user.contributed_repositories.order('stargazers_count DESC, rank DESC NULLS LAST')
  end

  def project_contributions
    paginate json: @repository_user.contributed_projects.visible.includes(:versions, :repository).order('rank DESC NULLS LAST')
  end

  def dependencies
    scope = @repository_user.favourite_projects.visible
    scope = scope.platform(params[:platform]) if params[:platform].present?
    paginate json: scope.paginate(page: page_number)
  end

  private

  def find_user
    @repository_user = RepositoryUser.host(current_host).visible.login(params[:login]).first
    @repository_user = RepositoryOrganisation.host(current_host).visible.login(params[:login]).first if @repository_user.nil?
    raise ActiveRecord::RecordNotFound if @repository_user.nil?
  end
end
