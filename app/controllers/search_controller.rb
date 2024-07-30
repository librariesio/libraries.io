# frozen_string_literal: true

class SearchController < ApplicationController
  before_action :ensure_logged_in

  def index
    @query = params[:q]
    @title = page_title
    @facets = []

    @any_criteria = params
      .values_at(:q, :platforms, :languages, :licenses, :keywords)
      .any?(&:present?)

    if use_pg_search?
      @projects = pg_search_projects(@query).paginate(page: params[:page])

      respond_to do |format|
        format.html { render :index_pg_search }
        format.atom
      end
    else
      @search = []
      @projects = []

      if @any_criteria
        @search = search_projects(@query)
        @suggestion = @search.response.suggest.did_you_mean.first if @query.present?
        @projects = @search.results.map { |result| ProjectSearchResult.new(result) }
        @facets = @search.response.aggregations
      end

      respond_to do |format|
        format.html
        format.atom
      end
    end
  end

  private

  helper_method :search_params
  def search_params
    params.permit(:q, :sort, :platforms, :languages, :licenses, :keywords)
  end

  def allowed_sorts
    %w[rank stars dependents_count dependent_repos_count latest_release_published_at created_at contributions_count]
  end

  def page_title
    return "Search for #{params[:q]}" if params[:q].present?

    modifiers = []
    modifiers << current_licenses if current_licenses.present?
    modifiers << current_platforms if current_platforms.present?
    modifiers << current_languages if current_languages.present?
    modifiers << current_keywords if current_keywords.present?

    modifier = " #{modifiers.compact.join(' ')} "

    case params[:sort]
    when "created_at"
      "New#{modifier}Projects"
    when "updated_at"
      "Updated#{modifier}Projects"
    when "latest_release_published_at"
      "Updated#{modifier}Projects"
    else
      "Popular#{modifier}Projects"
    end
  end
end
