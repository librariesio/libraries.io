class ProjectScoreCalculationBatch
  def self.run(platform, limit = 5000)
    # pull project ids from start of redis sorted set
    key = queue_key(platform)
    project_ids = REDIS.multi do
      REDIS.zrange key, 0, limit-1
      REDIS.zremrangebyrank key, 0, limit-1
    end.first

    # process
    batch = ProjectScoreCalculationBatch.new(platform, project_ids)
    new_project_ids = batch.process

    # put resulting ids back in the end of the set
    enqueue(platform, new_project_ids) if new_project_ids.any?
  end

  def self.enqueue(platform, project_ids)
    REDIS.zadd(queue_key(platform), project_ids.map{|id| [Time.now.to_i, id] })
  end

  def self.queue_key(platform)
    "project_score:#{platform.downcase}"
  end

  def initialize(platform, project_ids)
    @platform = platform
    @project_ids = project_ids
    @updated_projects = []
    @dependent_project_ids = []
    @maximums = ProjectScoreCalculator.maximums(@platform)
  end

  def process
    projects_scope.find_each do |project|
      score = ProjectScoreCalculator.new(project, @maximums).overall_score
      next if project.score == score
      project.update_columns(score: score,
                             score_last_calculated: Time.zone.now)
      @updated_projects << project if project.dependents_count > 0 && project.platform.downcase == @platform.downcase
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
    Project.platform(@platform)
           .includes(eager_loads)
           .where(id: @project_ids)
  end

  def eager_loads
    [{versions: {runtime_dependencies: {project: :versions}}}, :registry_users, {repository: :readme}]
  end
end
