class SearchController < ApplicationController
  def index
    @search = Project.search(params[:q], filters: {
      platform: params[:platforms],
      normalized_licenses: params[:licenses],
      language: params[:languages],
      keywords: params[:keywords]
    }, sort: params[:sort], order: params[:order]).paginate(page: params[:page])
    @suggestion = @search.response.suggest.did_you_mean.first
    @projects = @search.records.includes(:github_repository)
  end
end
