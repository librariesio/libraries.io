class SearchController < ApplicationController
  def index
    scope = Project.search(params[:q])
    scope = scope.platform(params[:platform]) if params[:platform].present?
    scope = scope.license(params[:license]) if params[:license].present?

    @licenses = Project.popular_licenses.limit(20)
    @platforms = Download.platforms.map{|p| p.to_s.demodulize }
    @projects = scope.paginate(page: params[:page])
  end
end
