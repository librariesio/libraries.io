class Api::MaintenanceStatsController < Api::ApplicationController
  before_action :require_internal_api_key, :find_project

  def enqueue
    @project.update_maintenance_stats_async(priority: :high)
    head :accepted
  end

  def begin_watching
    @project.update_maintenance_stats_async(priority: high) if @project.repository_maintenance_stats.length == 0
    head :accepted
  end
end
