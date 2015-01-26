class UsersController < ApplicationController
  def show
    @user = GithubUser.find(params[:id])
    @contributions = @user.github_contributions
                          .includes(:github_repository => :project)
                          .order('count DESC')
  end
end
