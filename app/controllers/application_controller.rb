class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_user, :logged_in?, :logged_out?

  before_action :mention_dependencyci

  private

  def max_page
    100
  end

  def page_number
    @page_number = params[:page].to_i rescue 1
    @page_number = 1 if @page_number < 2
    raise ActiveRecord::RecordNotFound if @page_number > max_page
    @page_number
  end

  def per_page_number
    @per_page_number = params[:per_page].to_i rescue 30
    @per_page_number = 30 if @per_page_number < 1
    raise ActiveRecord::RecordNotFound if @per_page_number > 100
    @per_page_number
  end

  def welcome_new_users
    if not logged_in? and not cookies[:hide_welcome_alert]
      flash.now[:show_welcome] = true # Actual content is at views/shared/_flash
    end
  end

  def mention_dependencyci
    if not cookies[:hide_dependencyci_alert]
      flash.now[:show_dependencyci] = true # Actual content is at views/shared/_flash
    end
  end

  def redirect_to_back_or_default(default = root_url, *args)
    if request.env['HTTP_REFERER'].present? && request.env['HTTP_REFERER'] != request.env['REQUEST_URI']
      redirect_to :back, *args
    else
      redirect_to default, *args
    end
  end

  def ensure_logged_in
    unless logged_in?
      session[:pre_login_destination] = request.original_url
      redirect_to login_path, notice: 'You must be logged in to view this content.'
    end
  end

  def current_user
    @current_user ||= User.find_by_id(session[:user_id])
  end

  def logged_in?
    !!current_user
  end

  def logged_out?
    !logged_in?
  end

  def find_platform(param = :id)
    @platform = Repositories::Base.platforms.find{|p| p.to_s.demodulize.downcase == params[param].downcase }
    raise ActiveRecord::RecordNotFound if @platform.nil?
    @platform_name = @platform.to_s.demodulize
  end

  def find_project
    @project = Project.platform(params[:platform]).where(name: params[:name]).includes(:github_repository, :versions).first
    @project = Project.platform(params[:platform]).where('lower(name) = ?', params[:name].downcase).includes(:github_repository, :versions).first if @project.nil?
    raise ActiveRecord::RecordNotFound if @project.nil?
    @color = @project.color
  end

  def current_platforms
    return [] if params[:platforms].blank?
    params[:platforms].split(',').map{|p| Repositories::Base.format_name(p) }.compact
  end

  def current_languages
    return [] if params[:languages].blank?
    params[:languages].split(',').map{|l| Languages::Language[l].to_s }.compact
  end

  def current_licenses
    return [] if params[:licenses].blank?
    params[:licenses].split(',').map{|l| Spdx.find(l).try(:id) }.compact
  end

  def current_keywords
    return [] if params[:keywords].blank?
    params[:keywords].split(',').compact
  end

  def format_sort
    return nil unless params[:sort].present?
    allowed_sorts.include?(params[:sort]) ? params[:sort] : nil
  end

  def format_order
    return nil unless params[:order].present?
    ['desc', 'asc'].include?(params[:order]) ? params[:order] : nil
  end

  def search_issues(labels)
    @search = paginate GithubIssue.search('', filters: {
      license: current_license,
      language: current_language,
      labels: labels
    }), page: page_number, per_page: per_page_number
    @github_issues = @search.records.includes(:github_repository)
  end

  def search_repos(query)
    es_query(GithubRepository, query, {
      license: current_licenses,
      language: current_language,
      keywords: current_keywords,
      platforms: current_platforms
    })
  end

  def search_projects(query)
    es_query(Project, query, {
      platform: current_platforms,
      normalized_licenses: current_licenses,
      language: current_languages,
      keywords_array: current_keywords
    })
  end

  def es_query(klass, query, filters)
    klass.search(query, filters: filters,
                        sort: format_sort,
                        order: format_order).paginate(page: page_number, per_page: per_page_number)
  end

  def find_version
    @version_count = @project.versions.size
    @github_repository = @project.github_repository
    if @version_count.zero?
      @versions = []
      if @github_repository.present?
        @github_tags = @github_repository.github_tags.published.order('published_at DESC').limit(10).to_a.sort
        if params[:number].present?
          @version = @github_repository.github_tags.published.find_by_name(params[:number])
          raise ActiveRecord::RecordNotFound if @version.nil?
        end
      else
        @github_tags = []
      end
      if @github_tags.empty?
        raise ActiveRecord::RecordNotFound if params[:number].present?
      end
    else
      @versions = @project.versions.sort.first(10)
      if params[:number].present?
        @version = @project.versions.find_by_number(params[:number])
        raise ActiveRecord::RecordNotFound if @version.nil?
      end
    end
    @version_number = @version.try(:number) || @project.latest_release_number
  end

  def load_repo
    full_name = [params[:owner], params[:name]].join('/')
    @github_repository = GithubRepository.where('lower(full_name) = ?', full_name.downcase).first
    raise ActiveRecord::RecordNotFound if @github_repository.nil?
    raise ActiveRecord::RecordNotFound unless authorized?
    redirect_to github_repository_path(@github_repository.owner_name, @github_repository.project_name), :status => :moved_permanently if full_name != @github_repository.full_name
  end

  def platform_scope(scope = Project)
    if params[:platform].present?
      find_platform(:platform)
      raise ActiveRecord::RecordNotFound if @platform_name.nil?
      scope.platform(@platform_name)
    else
      scope
    end
  end
end
