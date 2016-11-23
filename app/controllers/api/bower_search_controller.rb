class Api::BowerSearchController < Api::ApplicationController
  skip_before_action :check_api_key

  def index
    @search = paginate Project.search(params[:q] || '', filters: {
      platform: 'Bower',
    }, prefix: true, sort: format_sort, order: format_order), page: page_number, per_page: per_page_number
    ids = @search.map{|r| r.id.to_i }
    indexes = Hash[ids.each_with_index.to_a]
    @projects = @search.records.includes(:github_repository, :versions).sort_by { |u| indexes[u.id] }

    render json: project_json_response(@projects)
  end

  private

  def allowed_sorts
    ['rank', 'stars', 'dependents_count', 'dependent_repos_count', 'latest_release_published_at', 'created_at']
  end
end
