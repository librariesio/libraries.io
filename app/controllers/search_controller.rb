class SearchController < ApplicationController
  def index
    facets = Project.facets(:facet_limit => 40)

    @query = params[:q]
    @search = search_projects(@query)
    @suggestion = @search.response.suggest.did_you_mean.first
    @projects = @search.results.map{|result| ProjectSearchResult.new(result) }
    @facets = @search.response.aggregations
    @title = page_title
    @platforms = facets[:platforms].platform.buckets
    respond_to do |format|
      format.html
      format.atom
    end
  end

  private

  helper_method :search_params
  def search_params
    params.permit(:q, :sort, :platforms, :languages, :licenses, :keywords)
  end

  def allowed_sorts
    ['rank', 'stars', 'dependents_count', 'dependent_repos_count', 'latest_release_published_at', 'created_at', 'contributions_count']
  end

  def page_title
    return "Search for #{params[:q]} - Libraries.io" if params[:q].present?

    modifiers = []
    modifiers << current_licenses if current_licenses.present?
    modifiers << current_platforms if current_platforms.present?
    modifiers << current_languages if current_languages.present?
    modifiers << current_keywords if current_keywords.present?

    modifier = " #{modifiers.compact.join(' ')} "

    case params[:sort]
    when 'created_at'
      "New#{modifier}Projects - Libraries.io"
    when 'updated_at'
      "Updated#{modifier}Projects - Libraries.io"
    when 'latest_release_published_at'
      "Updated#{modifier}Projects - Libraries.io"
    else
      "Popular#{modifier}Projects - Libraries.io"
    end
  end
end
