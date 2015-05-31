class LicensesController < ApplicationController
  def index
    @licenses = Project.popular_licenses(:facet_limit => 150)
  end

  def show
    find_license
    @created = Project.license(@license.id).few_versions.order('projects.created_at DESC').limit(5).includes(:github_repository)
    @updated = Project.license(@license.id).many_versions.order('projects.latest_release_published_at DESC').limit(5).includes(:github_repository)
    @popular = Project.popular(filters: {normalized_licenses: @license.id}).first(5)
    @languages = Project.popular_languages(filters: {normalized_licenses: @license.id}).first(10)
    @platforms = Project.popular_platforms(filters: {normalized_licenses: @license.id}).first(10)
    @watched = Project.license(@license.id).most_watched.limit(4)
  end

  private

  def find_license
    @license = Spdx.find(params[:id])
    raise ActiveRecord::RecordNotFound if @license.nil?
    redirect_to license_path(@license.id), :status => :moved_permanently if @license.id != params[:id]
  end
end
