module TreeHelper
  def generate_dependency_tree(project, version, kind)
    @project_names = []
    @license_names = []
    full_graph = load_dependencies_for(version, nil, kind, 0)
    # if any of the same dependency twice in the tree

    # flatten tree

    # try to find common version number between all requirements

    # otherwise warn
  end

  def load_dependencies_for(version, dependency, kind, index)
    if version
      @license_names << version.project.try(:normalize_licenses)
      kind = index.zero? ? kind : 'normal'
      dependencies = version.dependencies.kind(kind).includes(project: :versions).limit(100).order(:project_name)
      {
        version: version,
        requirements: dependency.try(:requirements),
        dependencies: dependencies.map do |dep|
          if dep.project && !@project_names.include?(dep.project_name)
            @project_names << dep.project_name
            index < 10 ? load_dependencies_for(dep.latest_resolvable_version, dep, kind, index + 1) : ['MORE']
          else
            {
              version: dep.latest_resolvable_version,
              requirements: dep.try(:requirements),
              dependencies: []
            }
          end
        end
      }
    end
  end
end
