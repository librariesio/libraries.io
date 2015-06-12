class LicensesController < ApplicationController
  def index
    @licenses = Project.popular_licenses(:facet_limit => 150)
  end

  def show
    find_license
    @created = Project.license(@license.id).few_versions.order('projects.created_at DESC').limit(5).includes(:github_repository)
    @updated = Project.license(@license.id).many_versions.order('projects.latest_release_published_at DESC').limit(5).includes(:github_repository)
    @popular = Project.license(@license.id).order('projects.rank DESC').limit(5).includes(:github_repository)
    @watched = Project.license(@license.id).most_watched.limit(5)

    facets = Project.facets(filters: {normalized_licenses: @license.id}, :facet_limit => 10)

    @languages = facets[:languages][:terms]
    @platforms = facets[:platforms][:terms]
    @keywords = facets[:keywords][:terms]
  end

  private

  def find_license
    @license = Spdx.find(params[:id])
    raise ActiveRecord::RecordNotFound if @license.nil?
    redirect_to license_path(@license.id), :status => :moved_permanently if @license.id != params[:id]
  end
end
