class PlatformsController < ApplicationController
  def index
    @platforms = Project.popular_platforms
  end

  def show
    find_platform
    scope = Project.platform(@platform_name).maintained
    @created = scope.few_versions.order('projects.created_at DESC').limit(5).includes(:github_repository)
    @updated = scope.many_versions.order('projects.latest_release_published_at DESC').limit(5).includes(:github_repository)
    @watched = scope.most_watched.limit(5).includes(:github_repository)
    @dependend = scope.most_dependents.limit(5).includes(:github_repository)
    @popular = scope.order('projects.rank DESC').limit(5).includes(:github_repository)
    @trending = scope.includes(:github_repository).recently_created.hacker_news.limit(5)
    @dependent_repos = scope.most_dependent_repos.limit(5).includes(:github_repository)

    @color = @platform.color

    facets = Project.facets(filters: {platform: @platform_name}, :facet_limit => 10)

    @languages = facets[:languages][:terms]
    @licenses = facets[:licenses][:terms].reject{ |t| t.term.downcase == 'other' }
    @keywords = facets[:keywords][:terms]
  end
end
