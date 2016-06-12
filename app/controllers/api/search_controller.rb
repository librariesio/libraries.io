class Api::SearchController < Api::ApplicationController
  before_action :check_api_key

  def index
    @query = params[:q]
    @search = paginate Project.search(params[:q], filters: {
      platform: current_platform,
      normalized_licenses: current_license,
      language: current_language,
      keywords_array: params[:keywords]
    }, sort: format_sort, order: format_order)
    @projects = @search.records.includes(:github_repository, :versions)

    render json: @projects.as_json(only: Project::API_FIELDS, methods: [:package_manager_url, :stars, :keywords], include: {versions: {only: [:number, :published_at]} })
  end

  def searchcode
    render json: Project.where('updated_at > ?', 1.day.ago).pluck(:repository_url).compact.reject(&:blank?)
  end

  private

  def allowed_sorts
    ['rank', 'stars', 'dependents_count', 'latest_release_published_at', 'created_at']
  end

  def format_sort
    return nil unless params[:sort].present?
    allowed_sorts.include?(params[:sort]) ? params[:sort] : nil
  end

  def format_order
    return nil unless params[:order].present?
    ['desc', 'asc'].include?(params[:order]) ? params[:order] : nil
  end

  def current_platform
    Download.format_name(params[:platforms])
  end

  def current_language
    Languages::Language[params[:languages]].to_s if params[:languages].present?
  end

  def current_license
    Spdx.find(params[:licenses]).try(:id) if params[:licenses].present?
  end
end
