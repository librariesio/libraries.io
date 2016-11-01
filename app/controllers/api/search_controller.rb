class Api::SearchController < Api::ApplicationController
  skip_before_action :check_api_key, only: :searchcode

  def index
    @query = params[:q]
    @search = paginate Project.search(params[:q], filters: {
      platform: current_platforms,
      normalized_licenses: current_licenses,
      language: current_languages,
      keywords_array: current_keywords
    }, sort: format_sort, order: format_order), page: page_number, per_page: per_page_number
    @projects = @search.records.includes(:github_repository, :versions)

    render json: @projects.as_json(only: Project::API_FIELDS, methods: [:package_manager_url, :stars, :forks, :keywords, :latest_stable_release], include: {versions: {only: [:number, :published_at]} })
  end

  def searchcode
    render json: Project.where('updated_at > ?', 1.day.ago).pluck(:repository_url).compact.reject(&:blank?)
  end

  private

  def allowed_sorts
    ['rank', 'stars', 'dependents_count', 'latest_release_published_at', 'created_at']
  end
end
