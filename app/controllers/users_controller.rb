class UsersController < ApplicationController
  def show
    @user = GithubUser.find(params[:id])
  end
end
