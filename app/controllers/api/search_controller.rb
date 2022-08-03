# frozen_string_literal: true
class Api::SearchController < Api::ApplicationController
  # this is expensive, so let's restrict to internal api keys to avoid breaking hte site
  before_action :require_internal_api_key

  def index
    raise ActionController::BadRequest unless internal_api_key?

    @search = paginate search_projects(params[:q])
    @projects = @search.records.includes(:repository, :versions)

    render json: @projects
  end

  private

  def allowed_sorts
    ['rank', 'stars', 'dependents_count', 'dependent_repos_count', 'latest_release_published_at', 'created_at', 'contributions_count']
  end
end
