class DashboardController < ApplicationController
  before_action :ensure_logged_in

  def index
    @repos = current_user.repos
    @orgs = current_user.orgs
  end
end
