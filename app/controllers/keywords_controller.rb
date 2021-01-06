class KeywordsController < ApplicationController
  def index
    @keywords = Project.popular_keywords(:facet_limit => 160)
  end

  def show
    find_keyword

    scope = Project.keyword(@keyword).maintained
    @created = scope.few_versions.order('projects.created_at DESC').limit(5).includes(:repository)
    @updated = scope.many_versions.order('projects.latest_release_published_at DESC').limit(5).includes(:repository)
    @popular = scope.order('projects.rank DESC NULLS LAST').limit(5).includes(:repository)
    @dependend = scope.most_dependents.limit(5).includes(:repository)

    facets = Project.facets(filters: {keywords_array: @keyword}, :facet_limit => 10)

    @languages = facets[:languages].language.buckets
    @platforms = facets[:platforms].platform.buckets
    @licenses = facets[:licenses].normalized_licenses.buckets.reject{ |t| t['key'].downcase == 'other' }
  end

  private

  def find_keyword
    @keyword = params[:id].downcase if Project.keyword(params[:id].downcase).any?
    raise ActiveRecord::RecordNotFound if @keyword.nil?
  end
end
