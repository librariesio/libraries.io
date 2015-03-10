class PlatformsController < ApplicationController
  def index
    @platforms = Project.popular_platforms
  end

  def show
    find_platform
    @updated = Project.search('*', filters: {platform: @platform_name}, sort: 'updated_at').records.includes(:versions).first(5)
    @created = Project.search('*', filters: {platform: @platform_name}, sort: 'created_at').records.includes(:versions).first(5)

    @color = @platform.color
  end
end
