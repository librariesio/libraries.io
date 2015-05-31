class PlatformsController < ApplicationController
  def index
    @platforms = Project.popular_platforms
  end

  def show
    find_platform
    @updated = Project.search('*', filters: {platform: @platform_name}, sort: 'latest_release_published_at').records.includes(:github_repository).first(5)
    @created = Project.search('*', filters: {platform: @platform_name}, sort: 'created_at').records.includes(:github_repository).first(5)
    @watched = Project.platform(@platform_name).most_watched.limit(4)

    @color = @platform.color
  end
end
