class Api::BowerSearchController < Api::ApplicationController
  skip_before_action :check_api_key

  def index
    @search = paginate Project.search(params[:q] || '', filters: {
      platform: 'Bower',
    }, sort: format_sort, order: format_order), page: page_number, per_page: per_page_number
    @projects = @search.records.includes(:repository, :versions)

    render json: project_json_response(@projects)
  end

  private

  def allowed_sorts
    ['rank', 'stars', 'dependents_count', 'dependent_repos_count', 'latest_release_published_at', 'created_at']
  end
end
