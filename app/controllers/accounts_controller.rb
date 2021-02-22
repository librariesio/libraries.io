class AccountsController < ApplicationController
  before_action :ensure_logged_in

  def show

  end

  def optin
    current_user.update(optin: true)
    flash[:notice] = "You have accepted the terms of service and privacy policy. Thanks!"
    redirect_back(fallback_location: root_path)
  end

  def update
    if current_user.update(user_params)
      redirect_to account_path, notice: 'Preferences updated'
    else
      flash.now[:error] = "Couldn't update your email address"
      render action: :show
    end
  end

  def destroy
    current_user.destroy
    session.delete(:user_id)
    flash[:notice] = "Account deleted, we're sorry to see you go :'("
    redirect_to root_path
  end

  def disable_emails
    current_user.update(emails_enabled: false)
    flash[:notice] = "All Libraries.io Emails to your account have been disabled"
    redirect_back(fallback_location: root_path)
  end

  private

  def user_params
    params.require(:user).permit(:email, :emails_enabled, :hidden)
  end
end
