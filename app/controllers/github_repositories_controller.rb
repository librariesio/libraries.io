class GithubRepositoriesController < ApplicationController
  def index
    scope = GithubRepository.open_source.source.where.not(pushed_at: nil)
    scope = scope.where('lower(language) = ?', params[:language].downcase) if params[:language].present?
    scope = scope.where('lower(license) = ?', params[:license].downcase) if params[:license].present?

    @popular = scope.where('stargazers_count > 0').order('stargazers_count DESC').limit(6)
    @forked = scope.where('forks_count > 0').order('forks_count DESC').limit(6)
    @created = scope.order('created_at DESC').limit(6)
    @updated = scope.order('pushed_at DESC').limit(6)

    @languages = scope.group('lower(language)').count.reject{|k,v| k.blank? }.sort_by{|k,v| v }.reverse.first(25)
    @licenses = scope.group('lower(license)').count.reject{|k,v| k.blank? || k == 'other' }.sort_by{|k,v| v }.reverse.first(25)
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
