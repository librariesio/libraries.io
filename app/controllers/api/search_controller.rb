# frozen_string_literal: true

class Api::SearchController < Api::ApplicationController
  before_action :require_api_key

  def index
    if use_pg_search?
      @projects = pg_search_projects(params[:q]).includes(:repository, :versions).paginate(page: params[:page])
    else
      search = paginate search_projects(params[:q])
      @projects = search.records.includes(:repository, :versions)
    end

    render json: @projects
  end

  private

  def allowed_sorts
    %w[rank stars dependents_count dependent_repos_count latest_release_published_at created_at contributions_count]
  end
end
