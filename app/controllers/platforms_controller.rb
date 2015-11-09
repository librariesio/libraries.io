class PlatformsController < ApplicationController
  def index
    @platforms = Project.popular_platforms
  end

  def show
    find_platform

    @created = Project.platform(@platform_name).not_deprecated.few_versions.order('projects.created_at DESC').limit(5).includes(:github_repository)
    @updated = Project.platform(@platform_name).not_deprecated.many_versions.order('projects.latest_release_published_at DESC').limit(5).includes(:github_repository)
    @watched = Project.platform(@platform_name).not_deprecated.most_watched.limit(5)
    @dependend = Project.platform(@platform_name).not_deprecated.most_dependents.limit(5).includes(:github_repository)
    @popular = Project.platform(@platform_name).not_deprecated.order('projects.rank DESC').limit(5).includes(:github_repository)

    @color = @platform.color

    facets = Project.facets(filters: {platform: @platform_name}, :facet_limit => 10)

    @languages = facets[:languages][:terms]
    @licenses = facets[:licenses][:terms].reject{ |t| t.term.downcase == 'other' }
    @keywords = facets[:keywords][:terms]
  end
end
