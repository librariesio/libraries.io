class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_user, :logged_in?

  before_filter :welcome_new_users

  private

  def welcome_new_users
    if not cookies[:_libraries_session] # maybe not logged_in? instead?
      flash[:show_welcome] = true # Actual content is at views/shared/_flash
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

  def find_platform
    @platform = Download.platforms.find{|p| p.to_s.demodulize.downcase == params[:id].downcase }
    raise ActiveRecord::RecordNotFound if @platform.nil?
    @platform_name = @platform.to_s.demodulize
  end
end
