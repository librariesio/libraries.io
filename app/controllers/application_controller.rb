class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_user, :logged_in?, :logged_out?

  before_filter :welcome_new_users

  private

  def page_number
    @page_number = params[:page].to_i rescue 1
    @page_number = 1 if @page_number < 2
    raise ActiveRecord::RecordNotFound if @page_number > 100
    @page_number
  end

  def per_page_number
    @per_page_number = params[:per_page].to_i rescue 1
    @per_page_number = 1 if @per_page_number < 2
    raise ActiveRecord::RecordNotFound if @per_page_number > 100
    @per_page_number
  end

  def welcome_new_users
    if not logged_in? and not cookies[:hide_welcome_alert]
      flash.now[:show_welcome] = true # Actual content is at views/shared/_flash
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
    @platform = Download.platforms.find{|p| p.to_s.demodulize.downcase == params[param].downcase }
    raise ActiveRecord::RecordNotFound if @platform.nil?
    @platform_name = @platform.to_s.demodulize
  end

  def find_project
    @project = Project.platform(params[:platform]).where(name: params[:name]).includes(:github_repository).first
    @project = Project.platform(params[:platform]).where('lower(name) = ?', params[:name].downcase).includes(:github_repository).first if @project.nil?
    raise ActiveRecord::RecordNotFound if @project.nil?
    @color = @project.color
  end
end
