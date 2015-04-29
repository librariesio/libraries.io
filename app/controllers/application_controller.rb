class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_user, :logged_in?

  private

  def redirect_to_back_or_default(default = root_url, *args)
    if request.env['HTTP_REFERER'].present? && request.env['HTTP_REFERER'] != request.env['REQUEST_URI']
      redirect_to :back, *args
    else
      redirect_to default, *args
    end
  end

  def ensure_logged_in
    unless logged_in?
      session[:pre_login_destination] = "#{https_or_http?}://#{request.host_with_port}#{request.path}"
      redirect_to secure_login_url, notice: 'You must be logged in to view this content.'
    end
  end

  helper_method :secure_login_url
  def secure_login_url
    login_url(protocol: https_or_http?)
  end

  def https_or_http?
    ssl_configured? ? 'https' : 'http'
  end

  def ssl_configured?
    !Rails.env.development?
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
