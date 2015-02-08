class SearchController < ApplicationController
  def index
    scope = Project.search params[:q], filters: {
      platform: params[:platforms],
      normalized_licenses: params[:licenses]
    }

    @projects = scope.paginate(page: params[:page])
  end
end
