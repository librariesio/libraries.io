class GithubRepositoriesController < ApplicationController
  def index
    @language = Languages::Language[params[:language]] if params[:language].present?
    @license = Spdx.find(params[:license]) if params[:license].present?

    postfix = [@language, @license.try(:id)].compact.any? ? 'Repos' : 'Repositories'
    @title = [@language, @license.try(:id), postfix].compact.join(' ')

    orginal_scope = GithubRepository.maintained.open_source.source.where.not(pushed_at: nil)
    language_scope = @language.present? ? orginal_scope.where('lower(language) = ?', @language.name.downcase) : orginal_scope
    license_scope = @license.present? ? orginal_scope.where('lower(license) = ?', @license.id.downcase) : orginal_scope
    scope = @license.present? ? language_scope.where('lower(license) = ?', @license.id.downcase) : language_scope

    @popular = scope.where('stargazers_count > 0').order('stargazers_count DESC').limit(6)
    @forked = scope.where('forks_count > 0').order('forks_count DESC').limit(6)
    @created = scope.order('created_at DESC').limit(6)
    @updated = scope.order('pushed_at DESC').limit(6)

    @languages = license_scope.group('lower(language)').count.reject{|k,v| k.blank? }.sort_by{|k,v| v }.reverse.first(40)
    @licenses = language_scope.group('lower(license)').count.reject{|k,v| k.blank? || k == 'other' }.sort_by{|k,v| v }.reverse.first(25)
  end

  def search
    @query = params[:q]
    @search = GithubRepository.search(params[:q], filters: {
      license: current_license,
      language: current_language
    }, sort: format_sort, order: format_order).paginate(page: page_number, per_page: per_page_number)
    @suggestion = @search.response.suggest.did_you_mean.first
    @github_repositories = @search.records
    @title = page_title
    respond_to do |format|
      format.html
      format.atom
    end
  end

  def hacker_news
    @language = Languages::Language[params[:language]] if params[:language].present?
    @license = Spdx.find(params[:license]) if params[:license].present?

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
    @projects = @github_repository.projects
    @color = @github_repository.color
    @forks = @github_repository.forked_repositories.interesting.limit(5)
    @manifests = @github_repository.manifests.latest.limit(10).includes(repository_dependencies: :project)
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
    Languages::Language[params[:languages]].to_s if params[:languages].present?
  end

  helper_method :current_license
  def current_license
    Spdx.find(params[:licenses]).try(:id) if params[:licenses].present?
  end

  def format_sort
    return nil unless params[:sort].present?
    allowed_sorts.include?(params[:sort]) ? params[:sort] : nil
  end

  def format_order
    return nil unless params[:order].present?
    ['desc', 'asc'].include?(params[:order]) ? params[:order] : nil
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
end
