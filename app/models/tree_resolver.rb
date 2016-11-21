class TreeResolver
  attr_accessor :project_names
  attr_accessor :license_names
  attr_accessor :tree

  def initialize(version, kind)
    @version = version
    @kind = kind
    @project_names = []
    @license_names = []
    @tree = nil
  end

  def cached?
    Rails.cache.exist?(cache_key)
  end

  def tree
    @tree ||= load_dependencies_tree
  end

  def enqueue_tree_resolution
    TreeResolverWorker.perform_async(@version.id, @kind)
  end

  def load_dependencies_tree
    tree_data = Rails.cache.fetch cache_key, :expires_in => 1.day, race_condition_ttl: 2.minutes do
      generate_dependency_tree
    end
    @project_names = tree_data[:project_names]
    @license_names = tree_data[:license_names]
    @tree = tree_data[:tree]
  end

  private

  def generate_dependency_tree
    {
      tree: load_dependencies_for(@version, nil, @kind, 0),
      project_names: project_names,
      license_names: license_names
    }
  end

  def load_dependencies_for(version, dependency, kind, index)
    if version
      @license_names << version.project.try(:normalize_licenses)
      kind = index.zero? ? kind : 'normal'
      dependencies = version.dependencies.kind(kind).includes(project: :versions).limit(100).order(:project_name)
      {
        version: version,
        dependency: dependency,
        requirements: dependency.try(:requirements),
        dependencies: dependencies.map do |dep|
          if dep.project && !@project_names.include?(dep.project_name)
            @project_names << dep.project_name
            index < 10 ? load_dependencies_for(dep.latest_resolvable_version, dep, kind, index + 1) : ['MORE']
          else
            {
              version: dep.latest_resolvable_version,
              requirements: dep.try(:requirements),
              dependency: dep,
              dependencies: []
            }
          end
        end
      }
    end
  end

  def cache_key
    ['tree', @version, @kind]
  end
end
