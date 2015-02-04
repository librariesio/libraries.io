class UsersController < ApplicationController
  def show
    @user = GithubUser.where("lower(login) = ?", params[:login].downcase).first
    raise ActiveRecord::RecordNotFound if @user.nil?
    @contributions = @user.github_contributions
                          .includes(:github_repository => :projects)
                          .order('count DESC')
  end

  def legacy
    @user = GithubUser.find(params[:id])
    redirect_to user_path(@user), :status => :moved_permanently
  end
end
