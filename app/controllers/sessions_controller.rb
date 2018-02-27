class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create, :failure]
  before_action :read_only, only: [:new, :create]

  def new
    if params[:host_type].present?
      session[:pre_login_destination] = params[:return_to] if params[:return_to].present?
      redirect_to "/auth/" + params[:host_type]
    end
  end

  def enable_public
    session[:pre_login_destination] = repositories_path
    redirect_to "/auth/github_public"
  end

  def enable_private
    session[:pre_login_destination] = repositories_path
    redirect_to "/auth/github_private"
  end

  def create
    auth = request.env['omniauth.auth']

    identity = Identity.find_with_omniauth(auth)

    if identity.nil?
      identity = Identity.create_with_omniauth(auth)
    end

    identity.update_from_auth_hash(auth)

    if current_user
      if identity.user.nil?
        identity.user = current_user
        identity.save
      else
        flash[:notice] = 'Already connected'
      end
    else
      if identity.user.nil?
        user = User.new(optin: true)
        user.assign_from_auth_hash(auth)
        identity.user = user
        identity.save
      end

      flash[:notice] = nil
      session[:user_id] = identity.user.id
    end
    
    identity.user.update_columns(last_login_at: Time.current)
    identity.user.update_repo_permissions_async
    login_destination = pre_login_destination

    redirect_to(root_path) && return unless login_destination
    redirect_to login_destination
  end

  def destroy
    session.delete(:user_id)
    redirect_to root_path
  end

  def failure
    redirect_to root_path, notice: params[:message]
  end

  private

  def pre_login_destination
    destination = session[:pre_login_destination]
    session.delete :pre_login_destination
    return destination
  end
end
