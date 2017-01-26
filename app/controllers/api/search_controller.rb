class Api::SearchController < Api::ApplicationController
  def index
    @search = paginate search_projects(params[:q])
    ids = @search.map{|r| r.id.to_i }
    indexes = Hash[ids.each_with_index.to_a]
    @projects = @search.records.includes(:repository, :versions).sort_by { |u| indexes[u.id] }

    render json: project_json_response(@projects)
  end

  private

  def allowed_sorts
    ['rank', 'stars', 'dependents_count', 'dependent_repos_count', 'latest_release_published_at', 'created_at']
  end
end
