class Admin::UsersController < Admin::ApplicationController
  def sync
    @user = GithubUser.find_by_login(params[:id])
    GithubUpdateUserWorker.perform_async(@user.login)
    redirect_to user_path(@user.login), notice: 'Scheduled syncing this users data from GitHub'
  end
end
