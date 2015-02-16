class UsersController < ApplicationController
  def show
    @user = GithubUser.where("lower(login) = ?", params[:login].downcase).first
    raise ActiveRecord::RecordNotFound if @user.nil?
    @contributions = @user.github_contributions
                          .includes(:github_repository => :projects)
                          .order('count DESC').reject{|g| g.github_repository.try(:owner_name) == @user.login }
  end
end
