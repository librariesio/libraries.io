class Api::MaintenanceStatsController < Api::ApplicationController
  before_action :require_internal_api_key, :find_project

  def enqueue
    @project.update_maintenance_stats_async(priority: :high)
    head :accepted
  end

  def begin_watching
    @project.update_maintenance_stats_async(priority: high) unless @project.repository_maintenance_stats.exists?
    head :accepted
  end
end
