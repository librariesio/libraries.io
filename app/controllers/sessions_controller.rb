class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create, :failure]

  def new
    session[:pre_login_destination] = params[:return_to] if params[:return_to].present?
    redirect_to "/auth/github"
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

    if identity.user.nil?
      user = identity.find_existing_user || User.new
      user.assign_from_github_auth_hash(auth)
      identity.user = user
      identity.save
    end

    flash[:notice] = nil
    session[:user_id] = identity.user.id

    identity.user.update_repo_permissions_async

    redirect_to(root_path) && return unless pre_login_destination
    redirect_to pre_login_destination
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
    session[:pre_login_destination]
  end
end
