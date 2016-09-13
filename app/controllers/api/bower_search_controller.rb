class Api::BowerSearchController < Api::ApplicationController
  skip_before_action :check_api_key

  def index
    @query = params[:q]
    @search = paginate Project.search(params[:q] || '', filters: {
      platform: 'Bower',
    }, prefix: true, sort: format_sort, order: format_order), page: page_number, per_page: per_page_number
    @projects = @search.records.includes(:github_repository, :versions)

    render json: @projects.as_json(only: Project::API_FIELDS, methods: [:package_manager_url, :stars, :forks, :keywords], include: {versions: {only: [:number, :published_at]} })
  end

  private

  def allowed_sorts
    ['rank', 'stars', 'dependents_count', 'latest_release_published_at', 'created_at']
  end
end
