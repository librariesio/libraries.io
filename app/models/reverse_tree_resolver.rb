class ReverseTreeResolver
  class Node
    attr_reader :project_ids, :found_depth

    def initialize(project_ids, found_depth)
      @project_ids = Set.new(project_ids)
      @found_depth = found_depth
    end
  end

  attr_reader :reverse_dependency_sets

  def initialize
    @reverse_dependency_sets = {}
  end

  def find_all(project_id, current_depth: 0, max_depth: 5)
    return @reverse_dependency_sets if current_depth >= max_depth

    reverse_dependencies_for(project_id, current_depth: current_depth).project_ids.each do |reverse_dep_project_id|
      find_all(reverse_dep_project_id, current_depth: current_depth + 1, max_depth: max_depth)
    end

    @reverse_dependency_sets
  end

  def reverse_dependencies_for(project_id, current_depth:)
    @reverse_dependency_sets.fetch(project_id) do
      @reverse_dependency_sets[project_id] = Node.new(fetch_reverse_dependencies(project_id), current_depth)
    end
  end

  def fetch_reverse_dependencies(project_id)
    Dependency.includes(:version).where(project_id: project_id).pluck(Arel.sql("distinct versions.project_id"))
  end
end
