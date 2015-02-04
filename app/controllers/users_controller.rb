class UsersController < ApplicationController
  def show
    @user = GithubUser.find(params[:id])
    @contributions = @user.github_contributions
                          .includes(:github_repository => :projects)
                          .order('count DESC')
  end
end
