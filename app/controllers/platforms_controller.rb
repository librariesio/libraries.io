class PlatformsController < ApplicationController
  def index
    @platforms = Project.popular_platforms
  end

  def show
    find_platform
    scope = Project.platform(@platform_name).maintained
    @created = scope.few_versions.order('projects.created_at DESC').limit(5).includes(:github_repository, :versions)
    @updated = scope.many_versions.order('projects.latest_release_published_at DESC').limit(5).includes(:github_repository, :versions)
    @watched = scope.most_watched.limit(5).includes(:github_repository, :versions)
    @dependend = scope.most_dependents.limit(5).includes(:github_repository, :versions)
    @popular = scope.order('projects.rank DESC').limit(5).includes(:github_repository, :versions)
    @trending = scope.includes(:github_repository).recently_created.hacker_news.limit(5)

    @color = @platform.color

    facets = Project.facets(filters: {platform: @platform_name}, :facet_limit => 10)

    @languages = facets[:languages][:terms]
    @licenses = facets[:licenses][:terms].reject{ |t| t.term.downcase == 'other' }
    @keywords = facets[:keywords][:terms]
  end
end
