class Api::SearchController < Api::ApplicationController
  before_action :check_api_key

  def index
    @query = params[:q]
    @search = Project.search(params[:q], filters: {
      platform: params[:platforms],
      normalized_licenses: params[:licenses],
      language: params[:languages],
      keywords_array: params[:keywords]
    }, sort: params[:sort], order: params[:order]).paginate(page: params[:page])
    @projects = @search.records

    render json: @projects.as_json(only: Project::API_FIELDS, methods: [:package_manager_url, :stars], include: {versions: {only: [:number, :published_at]} })
  end

  def searchcode
    render json: Project.where('updated_at > ?', 1.day.ago).pluck(:repository_url).compact.reject(&:blank?)
  end
end
