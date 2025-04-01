# frozen_string_literal: true

class ExploreController < ApplicationController
  def index
    @platforms = Rails.cache.fetch("explore:platforms", expires_in: 1.day, race_condition_ttl: 2.minutes) do
      Project.maintained.group(:platform).order("count_id DESC").limit(28).count("id").keys
    end
    @languages = Rails.cache.fetch("explore:languages", expires_in: 1.day, race_condition_ttl: 2.minutes) do
      Project.maintained.where.not(language: nil).group(:language).order("count_id DESC").limit(21).count("id").keys
    end

    project_scope = Project.maintained.with_description
    @new_projects = project_scope.order("projects.created_at desc").limit(10)
  end
end
