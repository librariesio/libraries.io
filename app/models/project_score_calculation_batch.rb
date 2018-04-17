class ProjectScoreCalculationBatch
  def initialize(platform, project_ids)
    @platform = platform
    @project_ids = project_ids
    @updated_projects = []
    @dependent_project_ids = []
    @maximums = ProjectScoreCalculator.maximums(@platform)
  end

  def process
    projects_scope.find_each do |project|
      puts project.name
      score = ProjectScoreCalculator.new(project, @maximums).overall_score
      next if project.score == score
      project.update_columns(score: score,
                             score_last_calculated: Time.zone.now)
      @updated_projects << project if project.dependents_count > 0
    end

    calculate_dependents
  end

  def calculate_dependents
    @updated_projects.each do |project|
      @dependent_project_ids += project.dependent_project_ids
    end

    return @dependent_project_ids.uniq
  end

  private

  def projects_scope
    Project.platform(@platform).includes(eager_loads).where(id: @project_ids)
  end

  def eager_loads
    [{versions: {runtime_dependencies: :project}}, :registry_users, {repository: :readme}]
  end
end
