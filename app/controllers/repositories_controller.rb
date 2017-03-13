class RepositoriesController < ApplicationController
  def index
    postfix = [current_language, current_license, current_keywords].any?(&:present?) ? 'Repos' : 'Repositories'
    @title = [current_language, current_license, current_keywords, formatted_host, postfix].compact.join(' ')

    @popular = repo_search('rank')
    @forked = repo_search('forks_count')
    @created = repo_search('created_at')
    @updated = repo_search('updated_at')

    facets = Repository.facets(filters: {language: current_language, license: current_license, keywords: current_keywords, host_type: formatted_host}, :facet_limit => 20)

    @host_types = {} # facets[:host_type][:terms]
    @languages = {} # facets[:language][:terms]
    @licenses = {} # facets[:license][:terms].reject{ |t| t.term.downcase == 'other' }
    @keywords = {} # facets[:keywords][:terms]
  end

  def search
    @query = params[:q]
    @search = search_repos(@query)
    @suggestion = @search.response.suggest.did_you_mean.first
    @repositories = @search.records
    @title = page_title
    @facets = {} # @search.response.facets
    respond_to do |format|
      format.html
      format.atom
    end
  end

  def languages
    @languages = {} # Repository.search('', :facet_limit => 150).response.facets[:language][:terms]
  end

  def hacker_news
    @language = Languages::Language[params[:language]] if params[:language].present?

    original_scope = Repository.trending.open_source
    original_scope = original_scope.host(current_host) if current_host
    scope = @language.present? ? original_scope.where('lower(language) = ?', @language.name.downcase) : original_scope
    @repos = scope.hacker_news.paginate(page: page_number)

    @languages = original_scope.group('lower(language)').count.reject{|k,_v| k.blank? }.sort_by{|_k,v| v }.reverse.first(40)
  end

  def new
    @language = Languages::Language[params[:language]] if params[:language].present?

    original_scope = Repository.with_stars.open_source.source
    original_scope = original_scope.host(current_host) if current_host
    scope = @language.present? ? original_scope.where('lower(language) = ?', @language.name.downcase) : original_scope
    @repos = scope.recently_created.order('created_at DESC').paginate(page: page_number)

    @languages = original_scope.recently_created.group('lower(language)').count.reject{|k,_v| k.blank? }.sort_by{|_k,v| v }.reverse.first(40)
  end

  def show
    load_repo
    @contributors = @repository.contributors.order('count DESC').visible.limit(20)
    @projects = @repository.projects.limit(20).includes(:versions)
    @color = @repository.color
    @forks = @repository.forked_repositories.host(@repository.host_type).interesting.limit(5)
    @manifests = @repository.manifests.latest.limit(10).includes(repository_dependencies: {project: :versions})
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
    scope = @repository.contributions.where('count > 0').joins(:github_user)
    visible_scope = scope.where('github_users.hidden = ?', false).order('count DESC')
    @total = scope.sum(:count)
    @top_count = visible_scope.first.try(:count)
    @contributions = visible_scope.paginate(page: page_number)
    @any_hidden = scope.count > @contributions.total_entries
  end

  def forks
    load_repo
    @forks = @repository.forked_repositories.host(@repository.host_type).maintained.order('stargazers_count DESC').paginate(page: page_number)
  end

  def dependency_issues
    load_repo
    @repo_ids = @repository.dependency_repos.open_source.pluck(:id) - [@repository.id]
    search_issues(repo_ids: @repo_ids)
  end

  private

  def current_language
    params[:language] if params[:language].present?
  end

  def current_license
    params[:license] if params[:license].present?
  end

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

  def repo_search(sort)
    search = Repository.search('', filters: {
      license: current_license,
      language: current_language,
      keywords: current_keywords,
      platforms: current_platforms,
      host_type: formatted_host
    }, sort: sort, order: 'desc').paginate(per_page: 6, page: 1)
    search.records
  end
end
