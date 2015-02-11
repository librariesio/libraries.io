class PlatformsController < ApplicationController
  def index
    @platforms = Project.popular_platforms
  end

  def show
    find_platform
    @licenses = Project.popular_licenses(filters: {platform: @platform_name}).first(10)
    @updated = Project.search('*', filters: {platform: @platform_name}, sort: 'updated_at').records.first(5)
    @created = Project.search('*', filters: {platform: @platform_name}, sort: 'created_at').records.first(5)
    @contributors = GithubUser.top_for(@platform_name, 24)
    @popular = Project.popular(filters: { platform: @platform_name }).first(5)
    @languages = Project.popular_languages(filters: {platform: @platform_name}).first(10)
  end
end
