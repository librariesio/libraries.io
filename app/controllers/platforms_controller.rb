# frozen_string_literal: true
class PlatformsController < ApplicationController
  def index
    @platforms = Project.popular_platforms
  end

  def show
    find_platform
    scope = Project.platform(@platform_name).maintained
    @created = scope.few_versions.order('projects.created_at DESC').limit(5).includes(:repository)
    @updated = scope.many_versions.order('projects.latest_release_published_at DESC').limit(5).includes(:repository)
    @dependend = scope.most_dependents.limit(5).includes(:repository)
    @popular = scope.order('projects.rank DESC NULLS LAST').limit(5).includes(:repository)

    @color = @platform.color

    facets = Project.facets(filters: {platform: @platform_name}, facet_limit: 10)

    @languages = facets[:languages].language.buckets
    @licenses = facets[:licenses].normalized_licenses.buckets.reject{ |t| t['key'].downcase == 'other' }
    @keywords = facets[:keywords].keywords_array.buckets
  end
end
