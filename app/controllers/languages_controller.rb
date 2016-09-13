class LanguagesController < ApplicationController
  def index
    @languages = Project.popular_languages(:facet_limit => 160)
  end

  def show
    find_language

    scope = Project.language(@language).maintained
    @created = scope.few_versions.order('projects.created_at DESC').limit(5).includes(:github_repository, :versions)
    @updated = scope.many_versions.order('projects.latest_release_published_at DESC').limit(5).includes(:github_repository, :versions)
    @color = Languages::Language[@language].try(:color)
    @watched = scope.most_watched.limit(5).includes(:github_repository, :versions)
    @dependend = scope.most_dependents.limit(5).includes(:github_repository, :versions)
    @popular = scope.order('projects.rank DESC').limit(5).includes(:github_repository, :versions)

    facets = Project.facets(filters: { language: @language }, :facet_limit => 10)

    @platforms = facets[:platforms][:terms]
    @licenses = facets[:licenses][:terms].reject{ |t| t.term.downcase == 'other' }
    @keywords = facets[:keywords][:terms]
  end

  private

  def find_language
    @language = Project.language(params[:id]).first.try(:language)
    raise ActiveRecord::RecordNotFound if @language.nil?
    redirect_to language_path(@language), :status => :moved_permanently if @language != params[:id]
  end
end
