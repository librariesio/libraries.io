class Api::MaintenanceStatsController < Api::ApplicationController
  before_action :require_internal_api_key, :find_project

  def enqueue
    @project.update_maintenance_stats_async(priority: :high)
    head :ok
  end
end
