class PlatformsController < ApplicationController
  def index
    @platforms = Project.popular_platforms.sort_by(&:term)
  end

  def show
    find_platform
    scope = Project.platform(@platform_name)
    @licenses = scope.popular_licenses_sql.limit(8).to_a
    @updated = scope.limit(5).order('updated_at DESC')
    @created = scope.limit(5).order('created_at DESC')
    @contributors = GithubUser.top_for(@platform_name, 24)
    @popular = Project.popular(filters: { platform: @platform_name }).first(5)
  end
end
