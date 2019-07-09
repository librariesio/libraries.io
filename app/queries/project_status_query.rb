class ProjectStatusQuery
  def initialize(platform, requested_project_names)
    @platform = platform
    @requested_project_names = requested_project_names
  end

  def projects_by_name
    projects.merge(missing_projects)
  end

  private

  def projects
    @projects ||= fetch_projects(
      @requested_project_names,
      &platform_class.method(:project_find_names)
    )
  end

  def missing_projects
    return {} unless @platform.downcase == "go"

    fetch_projects(
      @requested_project_names.reject(&projects.method(:key?)),
      &PackageManager::Go.method(:resolved_name)
    )
  end

  def fetch_projects(requested_project_names, &resolver)
    resolved_project_names = requested_project_names
      .map { |requested_name| resolve_project_names(requested_name, &resolver) }
      .reduce({}, :merge)

    Project
      .visible
      .where(
        "lower(platform)=? AND lower(name) in (?)",
        @platform.downcase,
        resolved_project_names.keys
      )
      .includes(:repository, :versions, :repository_maintenance_stats)
      .find_each
      .index_by { |project| resolved_project_names[project.name.downcase] }
  end

  def resolve_project_names(requested_name)
    Array(yield(requested_name))
      .map { |resolved_name| [resolved_name.downcase, requested_name] }
      .to_h
  end

  def platform_class
    @platform_class ||= PackageManager::Base.find(@platform) || PackageManager::Base
  end
end
