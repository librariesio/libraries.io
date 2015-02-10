class PlatformsController < ApplicationController
  def index
    @platforms = Project.popular_platforms
  end

  def show
    find_platform
    scope = Project.platform(@platform_name)
    @licenses = Project.popular_licenses(filters: {platform: @platform_name}).first(10)
    @updated = scope.limit(5).order('updated_at DESC')
    @created = scope.limit(5).order('created_at DESC')
    @contributors = GithubUser.top_for(@platform_name, 24)
    @popular = Project.popular(filters: { platform: @platform_name }).first(5)
    @languages = Project.popular_languages(filters: {platform: @platform_name}).first(10)
  end
end
