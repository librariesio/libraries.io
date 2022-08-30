# frozen_string_literal: true
class RepositoriesController < ApplicationController
  before_action :ensure_logged_in, only: [:sync]

  def show
    load_repo
    @contributors = @repository.contributors.order('count DESC').visible.limit(20).select(:host_type, :name, :login, :uuid)
    @projects = @repository.projects.visible.limit(20).includes(:versions)
    @color = @repository.color
    @forks = @repository.forked_repositories.host(@repository.host_type).interesting.limit(5)
  end

  def sourcerank
    load_repo
  end

  def tags
    load_repo
    @tags = @repository.tags.published.order('published_at DESC, name DESC').paginate(page: page_number)
  end

  def contributors
    load_repo
    scope = @repository.contributions.where('count > 0').joins(:repository_user)
    visible_scope = scope.where('repository_users.hidden = ?', false).order('count DESC')
    @total = scope.sum(:count)
    @top_count = visible_scope.first.try(:count)
    @contributions = visible_scope.paginate(page: page_number)
    @any_hidden = scope.count > @contributions.total_entries
  end

  def forks
    load_repo
    @forks = @repository.forked_repositories.host(@repository.host_type).maintained.order('stargazers_count DESC, rank DESC NULLS LAST').paginate(page: page_number)
  end

  def dependencies
    load_repo
    @manifests = @repository.manifests.latest.limit(10).includes(repository_dependencies: {project: :versions})
    render layout: false
  end

  def sync
    load_repo
    if @repository.recently_synced?
      flash[:error] = "Repository has already been synced recently"
    else
      @repository.manual_sync(current_user.token)
      flash[:notice] = "Repository has been queued to be resynced"
    end
    redirect_back fallback_location: repository_path(@repository.to_param)
  end

  private

  def allowed_sorts
    ['rank', 'stargazers_count', 'contributions_count', 'created_at', 'pushed_at', 'subscribers_count', 'open_issues_count', 'forks_count', 'size']
  end
end
