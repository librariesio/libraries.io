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
end
