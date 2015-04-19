class DashboardController < ApplicationController
  def index
    @repos = current_user.repos
    @orgs = current_user.orgs
  end
end
