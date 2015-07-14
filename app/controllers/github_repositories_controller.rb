class GithubRepositoriesController < ApplicationController
  def index
    @language = Languages::Language[params[:language]] if params[:language].present?
    @license = Spdx.find(params[:license]) if params[:license].present?

    postfix = [@language, @license.try(:id)].compact.any? ? 'Repos' : 'Repositories'
    @title = [@language, @license.try(:id), postfix].compact.join(' ')

    orginal_scope = GithubRepository.open_source.source.where.not(pushed_at: nil)
    language_scope = @language.present? ? orginal_scope.where('lower(language) = ?', @language.name.downcase) : orginal_scope
    license_scope = @license.present? ? orginal_scope.where('lower(license) = ?', @license.id.downcase) : orginal_scope
    scope = @license.present? ? language_scope.where('lower(license) = ?', @license.id.downcase) : language_scope

    @popular = scope.where('stargazers_count > 0').order('stargazers_count DESC').limit(6)
    @forked = scope.where('forks_count > 0').order('forks_count DESC').limit(6)
    @created = scope.order('created_at DESC').limit(6)
    @updated = scope.order('pushed_at DESC').limit(6)

    @languages = license_scope.group('lower(language)').count.reject{|k,v| k.blank? }.sort_by{|k,v| v }.reverse.first(25)
    @licenses = language_scope.group('lower(license)').count.reject{|k,v| k.blank? || k == 'other' }.sort_by{|k,v| v }.reverse.first(25)
  end

  def show
    load_repo
    @contributors = @github_repository.github_contributions.order('count DESC').limit(20).includes(:github_user)
    @projects = @github_repository.projects
    @color = @github_repository.color
  end

  def contributors
    load_repo
    @contributors = @github_repository.github_contributions.order('count DESC').includes(:github_user).paginate(page: params[:page])
  end

  def load_repo
    full_name = [params[:owner], params[:name]].join('/')
    @github_repository = GithubRepository.where(full_name: full_name).first
    @github_repository = GithubRepository.where('lower(full_name) = ?', full_name.downcase).first if @github_repository.nil?
    raise ActiveRecord::RecordNotFound if @github_repository.nil?
    raise ActiveRecord::RecordNotFound unless authorized?
    redirect_to github_repository_path(@github_repository.owner_name, @github_repository.project_name), :status => :moved_permanently if full_name != @github_repository.full_name
  end

  def authorized?
    if @github_repository.private?
      current_user && current_user.can_read?(@github_repository)
    else
      true
    end
  end
end
