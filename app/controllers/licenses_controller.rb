class LicensesController < ApplicationController
  def index
    @licenses = Project.popular_licenses(:facet_limit => 150)
  end

  def show
    find_license
    @updated = Project.search('*', filters: {normalized_licenses: @license.id}, sort: 'updated_at').records.includes(:github_repository).first(5)
    @created = Project.search('*', filters: {normalized_licenses: @license.id}, sort: 'created_at').records.includes(:github_repository).first(5)
    @popular = Project.popular(filters: {normalized_licenses: @license.id}).first(5)
    @languages = Project.popular_languages(filters: {normalized_licenses: @license.id}).first(10)
    @platforms = Project.popular_platforms(filters: {normalized_licenses: @license.id}).first(10)
  end

  private

  def find_license
    @license = Spdx.find(params[:id])
    raise ActiveRecord::RecordNotFound if @license.nil?
    redirect_to license_path(@license.id), :status => :moved_permanently if @license.id != params[:id]
  end
end
