class SearchController < ApplicationController
  def index
    @projects = Project.search params[:q],
                               page: params[:page],
                               per_page: 30,
                               facets: facets,
                               smart_facets: false,
                               where: filters
  end

  def facets
    [:platform, :normalized_licenses]
  end

  def filters
    {
      platform: params[:platform],
      normalized_licenses: params[:license]
    }.compact
  end
end
