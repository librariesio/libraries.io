class RecommendationsController < ApplicationController
  before_action :ensure_logged_in

  def index
    if params[:language].present?
      @language = Project.language(params[:language].downcase).first.try(:language)
      raise ActiveRecord::RecordNotFound if @language.nil?
      scope = current_user.recommended_projects.language(@language)
    else
      scope = current_user.recommended_projects
    end

    if params[:license].present?
      @license = Spdx.find(params[:license]) if params[:license].present?
      raise ActiveRecord::RecordNotFound if @license.nil?
      scope = current_user.recommended_projects.license(@license.id)
    else
      scope = current_user.recommended_projects
    end

    if params[:platform].present?
      @platform = Project.platform(params[:platform].downcase).first.try(:platform)
      raise ActiveRecord::RecordNotFound if @platform.nil?
      scope = current_user.recommended_projects.platform(@platform)
    else
      scope = current_user.recommended_projects
    end

    @languages = current_user.recommended_projects.pluck('language').compact.uniq
    @licenses = current_user.recommended_projects.pluck('normalized_licenses').compact.flatten.uniq
    @platforms = current_user.recommended_projects.pluck('platform').compact.uniq
    @projects = scope.paginate(page: params[:page], per_page: 20)
  end
end
