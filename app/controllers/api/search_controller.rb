class Api::SearchController < Api::ApplicationController
  skip_before_action :check_api_key, only: :searchcode

  def index
    @search = paginate search_projects(params[:q])
    ids = @search.map{|r| r.id.to_i }
    indexes = Hash[ids.each_with_index.to_a]
    @projects = @search.records.includes(:github_repository, :versions).sort_by { |u| indexes[u.id] }

    render json: project_json_response(@projects)
  end

  def searchcode
    render json: Project.where('updated_at > ?', 1.day.ago).pluck(:repository_url).compact.reject(&:blank?)
  end

  private

  def allowed_sorts
    ['rank', 'stars', 'dependents_count', 'dependent_repos_count', 'latest_release_published_at', 'created_at']
  end
end
