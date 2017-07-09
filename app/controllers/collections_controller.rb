class CollectionsController < ApplicationController
  def index
    @languages = Project.popular_languages.first(40).map{|t| t['key'] }.select(&:present?)
  end

  def show
    find_language
    @search = Project.search(params[:keyword], {filters: {
        language: [@language],
        keywords: current_keywords,
        platform: current_platforms,
        normalized_licenses: current_licenses
      }}).paginate(page: page_number, per_page: per_page_number)

    @projects = @search.results.map{|result| ProjectSearchResult.new(result) }
    @facets = @search.response.aggregations
    raise ActiveRecord::RecordNotFound if @projects.empty?
  end

  private

  def find_language
    @language = Linguist::Language[params[:language]].try(:to_s)
    raise ActiveRecord::RecordNotFound if @language.nil?
  end
end
