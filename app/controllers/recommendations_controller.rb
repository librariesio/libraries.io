# frozen_string_literal: true
class RecommendationsController < ApplicationController
  before_action :ensure_logged_in

  def index
    if params[:language].present?
      @language = Linguist::Language[params[:language]].try(:to_s)
      raise ActiveRecord::RecordNotFound if @language.nil?
      scope = current_user.recommended_projects.language(@language)
    else
      scope = current_user.recommended_projects
    end

    if params[:license].present?
      @license = Spdx.find(params[:license]) if params[:license].present?
      raise ActiveRecord::RecordNotFound if @license.nil?
      scope = scope.license(@license.id)
    end

    scope = platform_scope(scope)

    @languages = current_user.recommended_projects.pluck('language').compact.uniq
    @licenses = current_user.recommended_projects.pluck('normalized_licenses').compact.flatten.uniq
    @platforms = current_user.recommended_projects.pluck('platform').compact.uniq
    @projects = scope.paginate(page: page_number, per_page: 20)
  end
end
