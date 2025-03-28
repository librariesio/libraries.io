# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Rails::Pagination
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_user, :logged_in?, :logged_out?, :current_host, :formatted_host, :tidelift_flash_partial

  before_action :extract_amplitude_device_id
  after_action :track_page_view
  around_action :trace_span

  private

  # Call from controllers to add additional properties to the Page Viewed
  # tracking event
  # @param properties [Hash]
  def add_tracking_properties(properties)
    @additional_tracking_properties ||= {}
    @additional_tracking_properties.merge!(properties)
  end

  def extract_amplitude_device_id
    AmplitudeService.request_ip = request.remote_ip
    @amplitude_enabled_for_request = AmplitudeService.enabled_for_request?
    return unless @amplitude_enabled_for_request

    cookie_name = "AMP_#{Rails.configuration.amplitude_api_key.first(10)}"
    amplitude_cookie = request.cookies[cookie_name]
    return unless amplitude_cookie

    # The cookie is base64 encoded and url encoded
    base64_decoded_cookie = Base64.decode64(amplitude_cookie)
    decoded_cookie = CGI.unescape(base64_decoded_cookie)
    cookie_data = JSON.parse(decoded_cookie)
    @amplitude_request_data = {
      device_id: cookie_data["deviceId"],
      session_id: cookie_data["sessionId"],
      ip: request.remote_ip,
      user_agent: request.user_agent,
    }
  rescue StandardError => e
    # don't allow analytics to break the app
    Bugsnag.notify(e)
  end

  def track_page_view
    return if request.xhr?

    event_properties = {
      url: request.original_url,
      referrer_url: request.referrer,
      controller: controller_name,
      action: action_name,
      params: request.filtered_parameters.except(:controller, :action, :format),
    }.merge(@additional_tracking_properties || {})

    AmplitudeService.event(
      event_type: AmplitudeService::EVENTS[:page_viewed],
      event_properties: event_properties,
      user: current_user,
      request_data: @amplitude_request_data
    )
  end

  def trace_span(&block)
    Datadog::Tracing.trace("endpoint##{controller_path}##{action_name}") do |_span, _trace|
      block.call
    end
  end

  def tidelift_flash_partial
    Dir[Rails.root.join("app", "views", "shared", "flashes", "*")].sample
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
    @page_number = begin
      params[:page].to_i
    rescue StandardError
      1
    end
    @page_number = 1 if @page_number < 2
    raise ActiveRecord::RecordNotFound if @page_number > max_page

    @page_number
  end

  def per_page_number
    @per_page_number = begin
      params[:per_page].to_i
    rescue StandardError
      30
    end
    @per_page_number = 30 if @per_page_number < 1
    raise ActiveRecord::RecordNotFound if @per_page_number > 100

    @per_page_number
  end

  def ensure_logged_in
    return if read_only

    unless logged_in?
      session[:pre_login_destination] = request.original_url
      redirect_to login_path, notice: "You must be logged in to view this content."
    end
  end

  def read_only
    redirect_to root_path, notice: "Can't perform this action, the site is in read-only mode temporarily." if in_read_only_mode?
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
    @project = Project.find_best!(params[:platform], params[:name], %i[repository versions])

    # There could be projects in the db whose package managers have since been removed
    raise ActiveRecord::RecordNotFound unless @project.platform_class_exists?

    @color = @project.color

    if @project.name != params[:name]
      redirect_to(
        # Unescape since url_for automatically escapes our already-escaped project name
        Addressable::URI.unescape(
          url_for(
            params
              .to_unsafe_h
              .merge({ "name" => CGI.escape(@project.name) })
          )
        )
      )
    end
  end

  def current_platforms
    return [] if params[:platforms].blank?

    params[:platforms].split(",").map { |p| PackageManager::Base.format_name(p) }.compact
  end

  def current_languages
    return [] if params[:languages].blank?

    params[:languages].split(",").map { |l| Linguist::Language[l].to_s }.compact
  end

  def current_language
    return [] if params[:language].blank?

    params[:language].split(",").map { |l| Linguist::Language[l].to_s }.compact
  end

  def current_licenses
    return [] if params[:licenses].blank?

    params[:licenses].split(",").map { |l| Spdx.find(l).try(:id) }.compact
  end

  def current_license
    return [] if params[:license].blank?

    params[:license].split(",").map { |l| Spdx.find(l).try(:id) }.compact
  end

  def current_keywords
    return [] if params[:keywords].blank?

    params[:keywords].split(",").compact
  end

  def format_sort
    return nil unless params[:sort].present?

    allowed_sorts.include?(params[:sort]) ? params[:sort] : nil
  end

  def format_order
    return nil unless params[:order].present?

    %w[desc asc].include?(params[:order]) ? params[:order] : nil
  end

  def custom_order
    return unless format_sort.present?

    "#{format_sort} #{format_order}"
  end

  def search_projects(query)
    es_query(Project, query, {
               platform: current_platforms,
               normalized_licenses: current_licenses,
               language: current_languages,
               keywords_array: current_keywords,
             })
  end

  def es_query(klass, query, filters)
    klass.search(query, filters: filters,
                        sort: format_sort,
                        order: format_order).paginate(page: page_number, per_page: per_page_number)
  end

  def pg_search_projects(term)
    ProjectSearchQuery.new(
      term,
      platforms: current_platforms,
      languages: current_languages,
      keywords: current_keywords,
      licenses: current_licenses,
      sort: format_sort
    ).results
  end

  def use_pg_search?
    (current_user&.admin_or_internal? && params.key?("force_pg")) || Rails.application.config.pg_search_projects_enabled
  end

  def find_version
    @version_count = @project.versions.size
    @repository = @project.repository
    if @version_count.zero?
      @versions = []
      if @repository.present?
        @tags = @repository.tags.published.order("published_at DESC").limit(10).to_a.sort
        if params[:number].present?
          @version = @repository.tags.published.find_by_name(params[:number])
          raise ActiveRecord::RecordNotFound if @version.nil? # rubocop: disable Metrics/BlockNesting
        end
      else
        @tags = []
      end
      raise ActiveRecord::RecordNotFound if @tags.empty? && params[:number].present?
    else
      @versions = @project.versions.order(published_at: :desc).limit(10)
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

    full_name = [params[:owner], params[:name]].join("/")
    @repository = Repository.host(current_host).where("lower(full_name) = ?", full_name.downcase).first
    raise ActiveRecord::RecordNotFound if @repository.nil?
    raise ActiveRecord::RecordNotFound if @repository.status == "Hidden"
    raise ActiveRecord::RecordNotFound unless authorized?

    redirect_to url_for(@repository.to_param), status: :moved_permanently if full_name != @repository.full_name
  end

  def authorized?
    if @repository.private?
      current_user&.can_read?(@repository)
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
    dependencies.map { |dependency| DependencySerializer.new(dependency) }
  end

  def load_tree_resolver
    @date = begin
      Date.parse(params[:date])
    rescue StandardError
      nil
    end
    number = params[:number].presence

    @version =
      if number
        @project.versions.find_by_number(number)
      elsif @date.present?
        @project.versions.where("versions.published_at <= ?", @date).select(&:stable?).min
      else
        @project.versions.select(&:stable?).min
      end
    raise ActiveRecord::RecordNotFound if @version.nil?

    @kind = params[:kind] || "runtime"
    @tree_resolver = TreeResolver.new(@version, @kind, @date)
  end

  def in_read_only_mode?
    ENV["READ_ONLY"].present?
  end

  # Overwrite so that we can attach the exception data to the request log via lograge.
  # This currently does not wrap the handler if it's passed via "with" instead of a block.
  def rescue_with_handler(exception)
    begin
      # Example log line that this parses: /Sites/libraries/app/controllers/application_controller.rb:274:in `do_something'
      line = exception.backtrace.grep(/app\/controllers\//).first || exception.backtrace.first
      filepath_and_line_number, method = line.to_s.split(":in ")
      filepath_and_line_number = filepath_and_line_number.gsub(Regexp.escape("#{Rails.root}/"), "")
      method = method.gsub(/[`']/, "").strip
      file, line = filepath_and_line_number.split(":")
      @rescued_error = { error_class: exception.class&.name, error_message: exception.message, error_method: method, error_file: file, error_line: line }
      # This information gets logged via append_info_to_payload+lograge in production.
      Rails.logger.info "Rescued #{exception.class&.name} in #{file}:#{line} (#{method})" if Rails.env.development?
    rescue StandardError => e
      # be sure we know if we raise an error from the error handler
      Bugsnag.notify(e)
    end
    super
  end

  # Attach extra data to process_action.action_controller notification for Lograge to log.
  def append_info_to_payload(payload)
    super
    payload[:rescued_error] = @rescued_error if @rescued_error
    payload[:current_user] = @current_user.id if @current_user
    # We've added our IP to ActionDispatch trusted_proxies, but not Rack::Request.ip_filter,
    # so use ActionDispatch's remote_ip instead of Rack's ip.
    payload[:remote_ip] = request.remote_ip
    if @current_api_key
      payload[:api_key] = {
        api_key_id: @current_api_key&.id,
        api_key_user_id: @current_api_key&.user_id,
        api_key_is_internal: @current_api_key&.is_internal,
      }
    end
    # helpful for tracking down github hook logs
    payload[:github_event] = @github_event if @github_event

    payload[:user_agent] = request.user_agent
    payload[:referer] = request.referer
  end
end
