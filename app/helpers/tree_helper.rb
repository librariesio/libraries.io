module TreeHelper
  def generate_dependency_tree(project, version, kind)
    @project_names =[]
    full_graph = load_dependencies_for(version, nil, kind, 0)
    # if any of the same dependency twice in the tree

    # flatten tree

    # try to find common version number between all requirements

    # otherwise warn
  end

  def load_dependencies_for(version, dependency, kind, index)
    if version
      kind = index.zero? ? kind : 'normal'
      dependencies = version.dependencies.kind(kind).includes(project: :versions).limit(100)
      if dependencies.length > 0
        {
          version: version,
          dependencies: dependencies.map do |dependency|
            if dependency.project && !@project_names.include?(dependency.project_name)
              @project_names << dependency.project_name
              {
                version: dependency.latest_resolvable_version,
                dependencies: index < 10 ? load_dependencies_for(dependency.latest_resolvable_version, dependency, kind, index + 1) : ['MORE']
              }
            else
              {
                version: dependency.latest_resolvable_version.try(:number)
              }
            end
          end
        }
      else
        {
          version: version
        }
      end
    else
      {
        version: version
      }
    end
  end
end
