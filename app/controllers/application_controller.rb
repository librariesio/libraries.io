class ApplicationController < ActionController::Base
  include Rails::Pagination
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_user, :logged_in?, :logged_out?, :current_host, :formatted_host

  private

  def current_host
    params[:host_type].try(:downcase)
  end

  def formatted_host
    RepositoryHost::Base.format(current_host)
  end

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
    @platform = PackageManager::Base.platforms.find{|p| p.to_s.demodulize.downcase == params[param].downcase }
    raise ActiveRecord::RecordNotFound if @platform.nil?
    @platform_name = @platform.to_s.demodulize
  end

  def find_project
    @project = Project.platform(params[:platform]).where(name: params[:name]).includes(:repository, :versions).first
    @project = Project.platform(params[:platform]).where('lower(name) = ?', params[:name].downcase).includes(:repository, :versions).first if @project.nil?
    raise ActiveRecord::RecordNotFound if @project.nil?
    @color = @project.color
  end

  def current_platforms
    return [] if params[:platforms].blank?
    params[:platforms].split(',').map{|p| PackageManager::Base.format_name(p) }.compact
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

  def search_issues(options = {})
    @search = paginate Issue.search(filters: {
      license: current_license,
      language: current_language,
      labels: options[:labels]
    }, repo_ids: options[:repo_ids]), page: page_number, per_page: per_page_number
    @issues = @search.records.includes(:repository)
    @facets = @search.response.aggregations
  end

  def first_pull_request_issues(labels)
    @search = paginate Issue.first_pr_search(filters: {
      license: current_license,
      language: current_language,
      labels: labels
    }), page: page_number, per_page: per_page_number
    @issues = @search.records.includes(:repository)
    @facets = @search.response.aggregations
  end

  def search_repos(query)
    es_query(Repository, query, {
      license: current_licenses,
      language: current_language,
      keywords: current_keywords,
      platforms: current_platforms,
      host_type: formatted_host
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
    @repository = @project.repository
    if @version_count.zero?
      @versions = []
      if @repository.present?
        @tags = @repository.tags.published.order('published_at DESC').limit(10).to_a.sort
        if params[:number].present?
          @version = @repository.tags.published.find_by_name(params[:number])
          raise ActiveRecord::RecordNotFound if @version.nil?
        end
      else
        @tags = []
      end
      if @tags.empty?
        raise ActiveRecord::RecordNotFound if params[:number].present?
      end
    else
      @versions = @project.versions.sort.first(10)
      if params[:number].present?
        @version = @project.versions.find_by_number(params[:number])
        raise ActiveRecord::RecordNotFound if @version.nil?
      else
        @version = @project.latest_release
      end
    end
    @version_number = @version.try(:number) || @project.latest_release_number
  end

  def load_repo
    raise ActiveRecord::RecordNotFound unless current_host.present?
    full_name = [params[:owner], params[:name]].join('/')
    @repository = Repository.host(current_host).where('lower(full_name) = ?', full_name.downcase).first
    raise ActiveRecord::RecordNotFound if @repository.nil?
    raise ActiveRecord::RecordNotFound unless authorized?
    redirect_to url_for(@repository.to_param), :status => :moved_permanently if full_name != @repository.full_name
  end

  def authorized?
    if @repository.private?
      current_user && current_user.can_read?(@repository)
    else
      true
    end
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

  helper_method :project_json_response
  def project_json_response(projects)
    projects.as_json(project_json_response_args)
  end

  def project_json_response_args
    {only: Project::API_FIELDS, methods: [:package_manager_url, :stars, :forks, :keywords, :latest_stable_release], include: {versions: {only: [:number, :published_at]} }}
  end

  def map_dependencies(dependencies)
    dependencies.map do |dependency|
      {
        project_name: dependency.project_name,
        name: dependency.project_name,
        platform: dependency.platform,
        requirements: dependency.requirements,
        latest_stable: dependency.try(:project).try(:latest_stable_release_number),
        latest: dependency.try(:project).try(:latest_release_number),
        deprecated: dependency.try(:project).try(:is_deprecated?),
        outdated: dependency.outdated?,
        filepath: dependency.try(:manifest).try(:filepath),
        kind: dependency.try(:manifest).try(:kind)
      }
    end
  end

  def load_tree_resolver
    @date = Date.parse(params[:date]) rescue Date.today

    if params[:number].present?
      @version = @project.versions.find_by_number(params[:number])
    else
      @version = @project.versions.where('versions.published_at <= ?', @date).select(&:stable?).sort.first
    end
    raise ActiveRecord::RecordNotFound if @version.nil?

    @kind = params[:kind] || 'runtime'
    @tree_resolver = TreeResolver.new(@version, @kind, @date)
  end
end
