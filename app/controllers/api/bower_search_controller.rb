# frozen_string_literal: true
class Api::BowerSearchController < Api::ApplicationController
  skip_before_action :check_api_key

  def index
    @search = paginate Project.search(params[:q] || '', filters: {
      platform: 'Bower',
    }, sort: format_sort, order: format_order, api: true), page: page_number, per_page: per_page_number
    @projects = @search.records.includes(:repository, :versions)

    render json: @projects
  end

  private

  def allowed_sorts
    ['rank', 'stars', 'dependents_count', 'dependent_repos_count', 'latest_release_published_at', 'created_at', 'contributions_count']
  end
end
