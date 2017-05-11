class Api::SearchController < Api::ApplicationController
  def index
    @search = paginate search_projects(params[:q])
    @projects = @search.records.includes(:repository, :versions)

    render json: @projects
  end

  private

  def allowed_sorts
    ['rank', 'stars', 'dependents_count', 'dependent_repos_count', 'latest_release_published_at', 'created_at', 'contributions_count']
  end
end
