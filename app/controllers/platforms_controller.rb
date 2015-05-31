class PlatformsController < ApplicationController
  def index
    @platforms = Project.popular_platforms
  end

  def show
    find_platform

    @created = Project.platform(@platform_name).few_versions.order('projects.created_at DESC').limit(5).includes(:github_repository)
    @updated = Project.platform(@platform_name).many_versions.order('projects.latest_release_published_at DESC').limit(5).includes(:github_repository)
    @watched = Project.platform(@platform_name).most_watched.limit(4)

    @color = @platform.color
  end
end
