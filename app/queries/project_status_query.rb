# frozen_string_literal: true

# Returns found projects by their requested names.
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

  # Returns a list of projects by their alternative lookup logic from Project.find_all_with_package_manager!,
  # using the names that weren't found with exact matches.
  # @return [Array<Project>] The projects that were found
  def missing_projects
    @missing_projects ||= Project.find_all_with_package_manager!(
      @platform,
      (@requested_project_names - exact_projects.keys),
      [:repository]
    ).compact
  end

  def platform_class
    @platform_class ||= PackageManager::Base.find(@platform) || PackageManager::Base
  end
end
