class Api::MaintenanceStatsController < Api::BulkProjectController
  before_action :require_internal_api_key
  before_action :find_project, except: [:begin_watching_bulk]

  def enqueue
    @project.update_maintenance_stats_async(priority: :high)
    head :accepted
  end

  def begin_watching
    begin_project_watch(@project)
    head :accepted
  end

  def begin_watching_bulk
    projects.each(&method(:begin_project_watch))
    head :accepted
  end

  def begin_project_watch(project)
    project.update_maintenance_stats_async(priority: :high) unless project.repository_maintenance_stats.exists?
  end
end
