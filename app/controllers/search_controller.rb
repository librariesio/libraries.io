class SearchController < ApplicationController
  def index
    @query = params[:q]
    @search = Project.search(params[:q], filters: {
      platform: current_platforms,
      normalized_licenses: current_licenses,
      language: current_languages,
      keywords_array: current_keywords
    }, sort: format_sort, order: format_order).paginate(page: page_number, per_page: per_page_number)
    @suggestion = @search.response.suggest.did_you_mean.first
    @projects = @search.records.includes(:github_repository, :versions)
    @title = page_title
    respond_to do |format|
      format.html
      format.atom
    end
  end

  private

  def allowed_sorts
    ['rank', 'stars', 'dependents_count', 'latest_release_published_at', 'created_at', 'github_contributions_count']
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
