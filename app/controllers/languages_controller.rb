class LanguagesController < ApplicationController
  def index
    @languages = Project.popular_languages(:facet_limit => 160)
  end

  def show
    find_language
    scope = Project.language(@language).maintained
    @created = scope.few_versions.order('projects.created_at DESC').limit(5).includes(:repository)
    @updated = scope.many_versions.order('projects.latest_release_published_at DESC').limit(5).includes(:repository)
    @color = Linguist::Language[@language].try(:color)
    @dependend = scope.most_dependents.limit(5).includes(:repository)
    @popular = scope.order('projects.rank DESC NULLS LAST').limit(5).includes(:repository)

    facets = Project.facets(filters: { language: @language }, :facet_limit => 10)

    @platforms = facets[:platforms].platform.buckets
    @licenses = facets[:licenses].normalized_licenses.buckets.reject{ |t| t['key'].downcase == 'other' }
    @keywords = facets[:keywords].keywords_array.buckets
  end

  private

  def find_language
    @language = Linguist::Language[params[:id]].try(:to_s)
    raise ActiveRecord::RecordNotFound if @language.nil?
    redirect_to language_path(@language), :status => :moved_permanently if @language != params[:id]
  end
end
