# frozen_string_literal: true
class ProjectScoreCalculationBatch
  def self.run(platform, limit = 1000)
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

  def self.run_all
    queue_status.each do |platform, count|
      run(platform) unless count.zero?
    end
  end

  def self.run_async(platform)
    ProjectScoreWorker.perform_async(platform)
  end

  def self.run_all_async
    queue_status.each do |platform, count|
      run_async(platform) unless count.zero?
    end
  end

  def self.enqueue(platform, project_ids)
    REDIS.zadd(queue_key(platform), project_ids.map{|id| [Time.now.to_i, id] })
  end

  def self.queue_key(platform)
    "project_score:#{platform.downcase}"
  end

  def self.queue_length(platform)
    REDIS.zcard(queue_key(platform))
  end

  def self.queue_status
    PackageManager::Base.platforms.map do |platform|
      name = platform.formatted_name.downcase
      [name, queue_length(name)]
    end.to_h
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
      begin
        score = ProjectScoreCalculator.new(project, @maximums).overall_score
        next if project.score == score
        project.update_columns(score: score,
                               score_last_calculated: Time.zone.now)
        @updated_projects << project if project.dependents_count > 0 && project.platform.downcase == @platform.downcase
      rescue
        nil
      end
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
    [{versions: {runtime_dependencies: {project: :versions}}}, :registry_users, {repository: [:readme]},  :published_tags]
  end
end
