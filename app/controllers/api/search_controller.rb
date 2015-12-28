class Api::SearchController < Api::ApplicationController
  before_action :check_api_key

  def index
    @query = params[:q]
    @search = Project.search(params[:q], filters: {
      platform: current_platform,
      normalized_licenses: current_license,
      language: current_language,
      keywords_array: params[:keywords]
    }, sort: params[:sort], order: params[:order]).paginate(page: params[:page])
    @projects = @search.records.includes(:github_repository)

    render json: @projects.as_json(only: Project::API_FIELDS, methods: [:package_manager_url, :stars], include: {versions: {only: [:number, :published_at]} })
  end

  def searchcode
    render json: Project.where('updated_at > ?', 1.day.ago).pluck(:repository_url).compact.reject(&:blank?)
  end

  private

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
