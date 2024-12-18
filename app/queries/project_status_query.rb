# frozen_string_literal: true

class ProjectStatusQuery
  def initialize(platform, requested_project_names)
    @platform = platform
    @requested_project_names = requested_project_names
  end

  def projects_by_name
    @projects_by_name ||= exact_projects.merge(missing_projects)
  end

  private

  def exact_projects
    @exact_projects ||= Project
      .visible
      .platform(@platform)
      .where(name: @requested_project_names)
      .includes(:repository)
      .find_each
      .index_by(&:name)
  end

  def missing_projects
    @missing_projects ||= Project
      .visible
      .lower_platform(@platform)
      .where("lower(name) in (?)", missing_project_find_names.keys)
      .includes(:repository)
      .find_each
      .index_by { |project| missing_project_find_names[project.name.downcase] }
  end

  def missing_project_find_names
    @missing_project_find_names ||= (@requested_project_names - exact_projects.keys)
      .each_with_object({}) do |requested_name, hash|
        platform_class
          .project_find_names(requested_name)
          .each { |find_name| hash[find_name.downcase] = requested_name }
      end
  end

  def platform_class
    @platform_class ||= PackageManager::Base.find(@platform) || PackageManager::Base
  end
end
