class ApplicationController < ActionController::Base
  include Rails::Pagination
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_user, :logged_in?, :logged_out?, :current_host, :formatted_host, :tidelift_flash_partial

  private

  def tidelift_flash_partial
    Dir[Rails.root.join('app', 'views', 'shared', 'flashes', '*')].sample
  end

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

  def ensure_logged_in
    return if read_only
    unless logged_in?
      session[:pre_login_destination] = request.original_url
      redirect_to login_path, notice: 'You must be logged in to view this content.'
    end
  end

  def read_only
    if in_read_only_mode?
      redirect_to root_path, notice: "Can't perform this action, the site is in read-only mode temporarily."
    end
  end

  def current_user
    return nil if in_read_only_mode?
    return nil if session[:user_id].blank?
    @current_user ||= User.includes(viewable_identities: :repository_user).find_by_id(session[:user_id])
  end

  def logged_in?
    !!current_user
  end

  def logged_out?
    !logged_in?
  end

  def find_platform(param = :id)
    @platform = PackageManager::Base.find(params[param])
    raise ActiveRecord::RecordNotFound if @platform.nil?
    @platform_name = @platform.formatted_name
  end

  def find_project
    @project = Project.find_with_includes!(params[:platform], params[:name], [:repository, :versions])
    @color = @project.color
  rescue ActiveRecord::RecordNotFound
    raise if params[:name].blank? || params[:platform]&.downcase != "go"

    resolved_name = PackageManager::Go.resolved_name(params[:name])
    if resolved_name != params[:name] && Project.known?(params[:platform], resolved_name)
      redirect_to(
        # Unescape since url_for automatically escapes our already-escaped resolved_name
        URI.unescape(
          url_for(
            params
              .to_unsafe_h
              .merge({ "name" => CGI.escape(resolved_name) })
          )
        )
      )
    else
      raise
    end
  end

  def find_project_lite
    @project = Project.visible.platform(params[:platform]).where(name: params[:name]).first
    raise ActiveRecord::RecordNotFound if @project.nil?
  end

  def current_platforms
    return [] if params[:platforms].blank?
    params[:platforms].split(',').map{|p| PackageManager::Base.format_name(p) }.compact
  end

  def current_languages
    return [] if params[:languages].blank?
    params[:languages].split(',').map{|l| Linguist::Language[l].to_s }.compact
  end

  def current_language
    return [] if params[:language].blank?
    params[:language].split(',').map{|l| Linguist::Language[l].to_s }.compact
  end

  def current_licenses
    return [] if params[:licenses].blank?
    params[:licenses].split(',').map{|l| Spdx.find(l).try(:id) }.compact
  end

  def current_license
    return [] if params[:license].blank?
    params[:license].split(',').map{|l| Spdx.find(l).try(:id) }.compact
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

  def custom_order
    return unless format_sort.present?
    "#{format_sort} #{format_order}"
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
      license: current_license,
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
    raise ActiveRecord::RecordNotFound if @repository.status == 'Hidden'
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
      scope.platform(@platform_name).visible
    else
      scope
    end
  end

  def map_dependencies(dependencies)
    dependencies.map {|dependency| DependencySerializer.new(dependency) }
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

  def in_read_only_mode?
    ENV['READ_ONLY'].present?
  end
end
