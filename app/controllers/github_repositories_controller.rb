class GithubRepositoriesController < ApplicationController
  def index
    scope = GithubRepository.open_source
    scope = scope.where(language: params[:language]) if params[:language].present?
    scope = scope.where(license: params[:license]) if params[:license].present?

    @popular = scope.order('stargazers_count DESC').limit(5)
    @forked = scope.where('forks_count > 0').order('forks_count DESC').limit(5)
    @created = scope.order('created_at DESC').limit(5)
    @updated = scope.order('updated_at DESC').limit(5)

    @languages = scope.group('lower(language)').count.reject{|k,v| k.blank? }.sort_by{|k,v| v }.reverse.first(20)
    @licenses = scope.group('lower(license)').count.reject{|k,v| k.blank? }.sort_by{|k,v| v }.reverse.first(20)
  end

  def show
    full_name = [params[:owner], params[:name]].join('/')
    @github_repository = GithubRepository.where(full_name: full_name).first
    @github_repository = GithubRepository.where('lower(full_name) = ?', full_name.downcase).first if @github_repository.nil?
    raise ActiveRecord::RecordNotFound if @github_repository.nil?
    raise ActiveRecord::RecordNotFound unless authorized?
    redirect_to github_repository_path(@github_repository.owner_name, @github_repository.project_name), :status => :moved_permanently if full_name != @github_repository.full_name
    @contributors = @github_repository.github_contributions.order('count DESC').limit(20).includes(:github_user)
    @projects = @github_repository.projects
    @color = @github_repository.color
  end

  def authorized?
    if @github_repository.private?
      current_user && current_user.can_read?(@github_repository)
    else
      true
    end
  end
end
