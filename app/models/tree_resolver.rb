class TreeResolver
  attr_accessor :project_names
  attr_accessor :license_names

  def initialize(project, version, kind)
    @project = project
    @version = version
    @kind = kind
    @project_names = []
    @license_names = []
  end

  def generate_dependency_tree
    load_dependencies_for(@version, nil, @kind, 0)
  end

  private

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
end
