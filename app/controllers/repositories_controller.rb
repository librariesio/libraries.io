# frozen_string_literal: true
class RepositoriesController < ApplicationController
  before_action :ensure_logged_in, only: [:sync]

  def index
    postfix = [current_language, current_license, current_keywords].any?(&:present?) ? 'Repos' : 'Repositories'
    @title = [current_language, current_license, current_keywords, formatted_host, postfix].compact.join(' ')

    @popular = repo_search('rank')
    @forked = repo_search('forks_count')
    @created = repo_search('created_at')
    @updated = repo_search('updated_at')

    facets = Repository.facets(filters: {language: current_language, license: current_license, keywords: current_keywords, host_type: formatted_host}, facet_limit: 20)

    @host_types = facets[:host_type].host_type.buckets
    @languages = facets[:language].language.buckets
    @licenses = facets[:license].license.buckets.reject{ |t| t['key'].downcase == 'other' }
    @keywords = facets[:keywords].keywords.buckets
  end

  def languages
    @languages = Repository.search('', facet_limit: 150).response.aggregations[:language].language.buckets
  end

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

  def page_title
    return "Search for #{params[:q]} Repositories - Libraries.io" if params[:q].present?

    modifiers = []
    modifiers << current_license if current_license.present?
    modifiers << current_language if current_language.present?

    modifier = " #{modifiers.compact.join(' ')} "

    case params[:sort]
    when 'created_at'
      "New#{modifier}#{formatted_host} Repositories - Libraries.io"
    when 'updated_at'
      "Updated#{modifier}#{formatted_host} Repositories - Libraries.io"
    when 'latest_release_published_at'
      "Updated#{modifier}#{formatted_host} Repositories - Libraries.io"
    else
      "Popular#{modifier}#{formatted_host} Repositories - Libraries.io"
    end
  end

  helper_method :repos_cache_key
  def repos_cache_key(sort)
    ['v2', sort, current_license, current_language, current_keywords, current_platforms, current_host].flatten.reject(&:blank?).map(&:downcase)
  end

  def repo_search(sort)
    Rails.cache.fetch(repos_cache_key(sort), expires_in: 1.hour) do
      search = Repository.search('', filters: {
        license: current_license,
        language: current_language,
        keywords: current_keywords,
        host_type: formatted_host
      }, sort: sort, order: 'desc', no_facet: true).paginate(per_page: 6, page: 1)
      search.results.map{|result| RepositorySearchResult.new(result) }
    end
  end
end
