class AccountsController < ApplicationController
  before_action :ensure_logged_in

  def show

  end

  def update
    if current_user.update_attributes(user_params)
      redirect_to account_path, notice: 'Email updated'
    else
      flash.now[:error] = "Couldn't update your email address"
      render action: :show
    end
  end

  private

  def user_params
    params.require(:user).permit(:email)
  end
end
