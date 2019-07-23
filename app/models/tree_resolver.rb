class TreeResolver
  MAX_TREE_DEPTH = 15

  def initialize(version, kind, date = nil)
    @version = version
    @kind = kind
    @date = date
    @project_names = Set.new
    @license_names = Set.new
  end

  def cached?
    Rails.cache.exist?(cache_key)
  end

  def tree
    @tree ||= load_dependencies_tree
  end

  def enqueue_tree_resolution
    TreeResolverWorker.perform_async(@version.id, @kind, @date)
  end

  def load_dependencies_tree
    tree_data = Rails.cache.fetch(
      cache_key,
      expires_in: 1.day,
      race_condition_ttl: 2.minutes,
      &method(:generate_dependency_tree)
    )
    @project_names = tree_data[:project_names]
    @license_names = tree_data[:license_names]
    @tree = tree_data[:tree]
  end

  def project_names
    @project_names.to_a
  end

  def license_names
    @license_names.to_a
  end

  private

  def generate_dependency_tree(_key)
    {
      tree: load_dependencies_for(@version, nil, @kind, 0),
      project_names: @project_names,
      license_names: @license_names,
    }
  end

  def load_dependencies_for(version, dependency, kind, index)
    return unless version

    append_license_names(version)
    should_fetch = append_project_name(dependency)

    return if index > MAX_TREE_DEPTH

    dependencies = should_fetch ? fetch_dependencies(version, kind) : []

    {
      version: version,
      requirements: dependency&.requirements,
      dependency: dependency,
      normalized_licenses: version.project.normalized_licenses,
      dependencies: dependencies
        .map { |dep| load_dependencies_for(dep.latest_resolvable_version(@date), dep, "runtime", index + 1) }
        .compact,
    }
  end

  def cache_key
    ["tree", @version, @kind, @date].compact
  end

  def append_project_name(dependency)
    return true unless dependency
    @project_names.add?(dependency.project_name).present?
  end

  def append_license_names(version)
    version
      .project
      .normalized_licenses
      .each(&@license_names.method(:add))
  end

  def fetch_dependencies(version, kind)
    version
      .dependencies
      .kind(kind)
      .includes(project: :versions)
      .limit(100)
      .order(:project_name)
  end
end
