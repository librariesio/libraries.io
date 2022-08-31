# frozen_string_literal: true
class ExploreController < ApplicationController
  def index
    @platforms = Project.maintained.group(:platform).order('count_id DESC').limit(28).count('id').keys
    @languages = Project.maintained.group(:language).order('count_id DESC').limit(21).count('id').keys

    project_scope = Project.includes(:repository).maintained.with_description

    @new_projects = project_scope.order('projects.created_at desc').limit(10)
  end
end
