# frozen_string_literal: true

class Api::SearchController < Api::ApplicationController
  before_action :require_api_key

  def index
    include_versions = params.fetch(:include_versions, "true") == "true"

    if use_pg_search?
      @projects = pg_search_projects(params[:q]).strict_loading.includes(:repository)
      @projects = @projects.includes(:versions) if include_versions
      @projects = @projects.paginate(page: params[:page])
    else
      search = paginate search_projects(params[:q])
      @projects = search.records.includes(:repository)
      @projects = @projects.includes(:versions) if include_versions
    end

    render json: @projects, each_serializer: ProjectSerializer, include_versions: include_versions
  end

  private

  def allowed_sorts
    %w[rank stars dependents_count dependent_repos_count latest_release_published_at created_at contributions_count]
  end
end
