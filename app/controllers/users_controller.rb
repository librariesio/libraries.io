class UsersController < ApplicationController
  def show
    @user = GithubUser.where("lower(login) = ?", params[:login].downcase).first
    raise ActiveRecord::RecordNotFound if @user.nil?
    @repositories = @user.repositories.includes(:projects).reject{|g| g.projects.empty? }
    @contributions = @user.github_contributions
                          .includes(:github_repository => :projects)
                          .order('count DESC').reject{|g| g.github_repository.nil? || g.github_repository.owner_name == @user.login || g.github_repository.projects.empty? }
  end
end
