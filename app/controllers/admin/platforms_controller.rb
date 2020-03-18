# frozen_string_literal: true

class Admin::PlatformsController < ApplicationController
  def index
    @platforms = Project.popular_platforms
  end

  def show
    find_platform

    top_projects = Project.platform(@platform_name).order("(dependent_repos_count) DESC NULLS LAST").limit(1000).includes(:repository)

    total = top_projects.sum(&:dependent_repos_count)

    groups = top_projects.group_by { |pr| pr.try(:repository).try(:full_name).try(:split, "/").try(:first) }

    usage = []

    groups.each do |owner_name, projects|
      if owner_name.present? && projects.length > 1 # multirepo
        name = owner_name + "*"
        count = projects.sum(&:dependent_repos_count)
        contributors = projects.sum(&:contributions_count)

        usage << [name, count, projects.length, contributors]
      else
        projects.each do |project|
          name = project.name
          count = project.dependent_repos_count

          usage << [name, count, 1, project.try(:repository).try(:contributions_count)]
        end
      end
    end

    @rows = []
    running_total = 0

    usage.sort_by(&:second).reverse.each do |dep|
      running_total += dep[1]
      if total.zero?
        0
      else
        percentage = (running_total / total.to_f * 100).round
      end
      @rows << [dep[0], dep[1], running_total, percentage, dep[2]]
    end

    @rows = @rows.first(200)
  end
end
