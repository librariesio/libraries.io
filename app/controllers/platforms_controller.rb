# frozen_string_literal: true

class PlatformsController < ApplicationController
  def index
    @platforms = Project.maintained.group(:platform).order("count_id DESC").count("id").map { |k, v| { "key" => k, "doc_count" => v } }
  end

  def show
    find_platform
    scope = Project.platform(@platform_name).maintained
    @created = scope.few_versions.order("projects.created_at DESC").limit(5).includes(:repository)
    @updated = scope.many_versions.order("projects.latest_release_published_at DESC").limit(5).includes(:repository)
    @dependend = scope.most_dependents.limit(5).includes(:repository)
    @popular = scope.order("projects.rank DESC NULLS LAST").limit(5).includes(:repository)

    @color = @platform.color
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end
end
