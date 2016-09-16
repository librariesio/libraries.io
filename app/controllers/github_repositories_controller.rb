class GithubRepositoriesController < ApplicationController
  def index
    postfix = [current_language, current_license, current_keywords].any?(&:present?) ? 'Repos' : 'Repositories'
    @title = [current_language, current_license, current_keywords, postfix].compact.join(' ')

    @popular = repo_search('stargazers_count')
    @forked = repo_search('forks_count')
    @created = repo_search('created_at')
    @updated = repo_search('pushed_at')

    facets = GithubRepository.facets(filters: {language: current_language, license: current_license, keywords: current_keywords}, :facet_limit => 20)

    @languages = facets[:language][:terms]
    @licenses = facets[:license][:terms].reject{ |t| t.term.downcase == 'other' }
    @keywords = facets[:keywords][:terms]
  end

  def search
    @query = params[:q]
    @search = GithubRepository.search(params[:q], filters: {
      license: current_licenses,
      language: current_language,
      keywords: current_keywords,
      platforms: current_platforms
    }, sort: format_sort, order: format_order).paginate(page: page_number, per_page: per_page_number)
    @suggestion = @search.response.suggest.did_you_mean.first
    @github_repositories = @search.records
    @title = page_title
    respond_to do |format|
      format.html
      format.atom
    end
  end

  def languages
    @languages = GithubRepository.search('', :facet_limit => 150).response.facets[:language][:terms]
  end

  def hacker_news
    @language = Languages::Language[params[:language]] if params[:language].present?

    orginal_scope = GithubRepository.maintained.open_source.where.not(pushed_at: nil).recently_created.where('stargazers_count > 0')
    scope = @language.present? ? orginal_scope.where('lower(language) = ?', @language.name.downcase) : orginal_scope
    @repos = scope.hacker_news.paginate(page: page_number)

    @languages = orginal_scope.group('lower(language)').count.reject{|k,v| k.blank? }.sort_by{|k,v| v }.reverse.first(40)
  end

  def new
    @language = Languages::Language[params[:language]] if params[:language].present?

    orginal_scope = GithubRepository.maintained.open_source.source.where.not(pushed_at: nil)
    scope = @language.present? ? orginal_scope.where('lower(language) = ?', @language.name.downcase) : orginal_scope
    @repos = scope.recently_created.order('created_at DESC').paginate(page: page_number)

    @languages = orginal_scope.recently_created.group('lower(language)').count.reject{|k,v| k.blank? }.sort_by{|k,v| v }.reverse.first(40)
  end

  def show
    load_repo
    @contributors = @github_repository.contributors.order('count DESC').visible.limit(20)
    @projects = @github_repository.projects.limit(20).includes(:versions)
    @color = @github_repository.color
    @forks = @github_repository.forked_repositories.interesting.limit(5)
    @manifests = @github_repository.manifests.latest.limit(10).includes(repository_dependencies: {project: :versions})
  end

  def tags
    load_repo
    @tags = @github_repository.github_tags.published.order('published_at DESC, name DESC').paginate(page: page_number)
  end

  def contributors
    load_repo
    @contributors = @github_repository.contributors.order('count DESC').visible.paginate(page: page_number)
  end

  def forks
    load_repo
    @forks = @github_repository.forked_repositories.maintained.order('stargazers_count DESC').paginate(page: page_number)
  end

  def load_repo
    full_name = [params[:owner], params[:name]].join('/')
    @github_repository = GithubRepository.where('lower(full_name) = ?', full_name.downcase).first
    raise ActiveRecord::RecordNotFound if @github_repository.nil?
    raise ActiveRecord::RecordNotFound unless authorized?
    redirect_to github_repository_path(@github_repository.owner_name, @github_repository.project_name), :status => :moved_permanently if full_name != @github_repository.full_name
  end

  private

  def authorized?
    if @github_repository.private?
      current_user && current_user.can_read?(@github_repository)
    else
      true
    end
  end

  def current_language
    params[:language] if params[:language].present?
  end

  def current_license
    params[:license] if params[:license].present?
  end

  def allowed_sorts
    ['stargazers_count', 'github_contributions_count', 'created_at', 'pushed_at', 'subscribers_count', 'open_issues_count', 'forks_count', 'size']
  end

  def page_title
    return "Search for #{params[:q]} - Libraries" if params[:q].present?

    modifiers = []
    modifiers << current_license if current_license.present?
    modifiers << current_language if current_language.present?

    modifier = " #{modifiers.compact.join(' ')} "

    case params[:sort]
    when 'created_at'
      "New#{modifier}Github Repositories - Libraries"
    when 'updated_at'
      "Updated#{modifier}Github Repositories - Libraries"
    when 'latest_release_published_at'
      "Updated#{modifier}Github Repositories - Libraries"
    else
      "Popular#{modifier}Github Repositories - Libraries"
    end
  end

  def repo_search(sort)
    search = GithubRepository.search('', filters: {
      license: current_license,
      language: current_language,
      keywords: current_keywords,
      platforms: current_platforms
    }, sort: sort, order: 'desc').paginate(per_page: 6, page: 1)
    search.records
  end
end
