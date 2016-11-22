class LicensesController < ApplicationController
  def index
    @licenses = Project.popular_licenses(:facet_limit => 150)
  end

  def show
    find_license
    scope = Project.license(@license.id).maintained
    @created = scope.few_versions.order('projects.created_at DESC').limit(5).includes(:github_repository)
    @updated = scope.many_versions.order('projects.latest_release_published_at DESC').limit(5).includes(:github_repository)
    @popular = scope.order('projects.rank DESC').limit(5).includes(:github_repository)
    @watched = scope.most_watched.limit(5).includes(:github_repository)
    @dependend = scope.most_dependents.limit(5).includes(:github_repository)
    @dependent_repos = scope.most_dependent_repos.limit(5).includes(:github_repository)

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
