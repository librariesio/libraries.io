# frozen_string_literal: true

class RepositoryTreeResolver
  attr_accessor :project_names, :license_names

  def initialize(repository, date = nil)
    @repository = repository
    @manifests = repository.manifests.kind("manifest")
    @project_names = []
    @license_names = []
    @tree = nil
    @date = date
  end

  def cached?
    Rails.cache.exist?(cache_key)
  end

  def platforms
    @platforms ||= @manifests.pluck(:platform).map(&:downcase).uniq.select do |platform|
      package_manager = PackageManager::Base.find(platform)
      package_manager && package_manager::HAS_VERSIONS # can only resolve trees for platforms with versions
    end
  end

  def tree
    @tree ||= load_dependencies_tree
  end

  def enqueue_tree_resolution
    RepositoryTreeResolverWorker.perform_async(@repository.id, @date)
  end

  def load_dependencies_tree
    tree_data = Rails.cache.fetch cache_key, expires_in: 1.day, race_condition_ttl: 2.minutes do
      generate_dependency_tree
    end

    @project_names = tree_data[:project_names]
    @license_names = tree_data[:license_names]
    @tree = tree_data[:tree]
  end

  private

  def generate_dependency_tree
    {
      tree: load_dependencies_for_platforms,
      project_names: project_names,
      license_names: license_names,
    }
  end

  def load_dependencies_for_platforms
    tree = {}
    platforms.map do |platform|
      manifests = @manifests.select { |m| m.platform.downcase == platform }

      dependencies = []
      manifests.each do |manifest|
        manifest.repository_dependencies.each do |repository_dependency|
          dependencies << repository_dependency
        end
      end
      # resolve tree for each platform
      versions = dependencies.map(&:latest_resolvable_version)

      tree[platform] = versions.map { |version| load_dependencies_for(version, nil, "runtime", 0) }
    end
    tree
  end

  def load_dependencies_for(version, dependency, kind, index)
    if version
      @license_names << version.project.try(:normalize_licenses)
      kind = index.zero? ? kind : "runtime"
      dependencies = version.dependencies.kind(kind).includes(project: :versions).limit(100).order(:project_name)
      {
        version: version,
        dependency: dependency,
        requirements: dependency.try(:requirements),
        dependencies: dependencies.map do |dep|
          if dep.project && !@project_names.include?(dep.project_name)
            @project_names << "#{dep.platform}/#{dep.project_name}"
            index < 10 ? load_dependencies_for(dep.latest_resolvable_version(@date), dep, kind, index + 1) : ["MORE"]
          else
            {
              version: dep.latest_resolvable_version(@date),
              requirements: dep.try(:requirements),
              dependency: dep,
              dependencies: [],
            }
          end
        end,
      }
    end
  end

  def cache_key
    ["repository_tree", @repository, @kind, @date].compact
  end
end
