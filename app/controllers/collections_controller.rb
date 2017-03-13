class CollectionsController < ApplicationController
  def index
    @languages = Project.popular_languages.first(40).map(&:term)
  end

  def show
    find_language
    @search = Project.search(params[:keyword], {filters: {
        language: [@language],
        keywords: current_keywords,
        platform: current_platforms,
        normalized_licenses: current_licenses
      }}).paginate(page: page_number, per_page: per_page_number)
    ids = @search.map{|r| r.id.to_i }
    indexes = Hash[ids.each_with_index.to_a]
    @projects = @search.records.includes(:repository).sort_by { |u| indexes[u.id] }
    @facets = {} # @search.response.facets
    raise ActiveRecord::RecordNotFound if @projects.empty?
  end

  private

  def find_language
    @language = Project.language(params[:language]).first.try(:language)
    raise ActiveRecord::RecordNotFound if @language.nil?
  end
end
