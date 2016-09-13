class KeywordsController < ApplicationController
  def index
    @keywords = Project.popular_keywords(:facet_limit => 160)
  end

  def show
    find_keyword

    @created = Project.keyword(@keyword).few_versions.order('projects.created_at DESC').limit(5).includes(:github_repository, :versions)
    @updated = Project.keyword(@keyword).many_versions.order('projects.latest_release_published_at DESC').limit(5).includes(:github_repository, :versions)
    @watched = Project.keyword(@keyword).most_watched.limit(5).includes(:github_repository, :versions)
    @popular = Project.keyword(@keyword).order('projects.rank DESC').limit(5).includes(:github_repository, :versions)
    @dependend = Project.keyword(@keyword).most_dependents.limit(5).includes(:github_repository, :versions)

    facets = Project.facets(filters: {keywords_array: @keyword}, :facet_limit => 10)

    @languages = facets[:languages][:terms]
    @platforms = facets[:platforms][:terms]
    @licenses = facets[:licenses][:terms].reject{ |t| t.term.downcase == 'other' }
  end

  private

  def find_keyword
    @keyword = params[:id].downcase if Project.keyword(params[:id].downcase).any?
    raise ActiveRecord::RecordNotFound if @keyword.nil?
  end
end
