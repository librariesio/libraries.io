# frozen_string_literal: true

class Api::MaintenanceStatsController < Api::BulkProjectController
  before_action :require_internal_api_key
  before_action :find_project, only: %i[enqueue begin_watching]

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

  def begin_watching_repositories
    lookup_names = params.require(:repositories).map { |p| p.permit(%i[host_type full_name]).to_h.symbolize_keys }

    supported_host_types = ["github"]

    # we only support GitHub so grab a working token now so we
    # don't run into issues trying to find one in the loop for
    # each repository name
    auth_token = AuthToken.find_token(:v3)

    repos = lookup_names.map do |repo_host_and_name|
      return render json: { error: "#{repo_host_and_name[:host_type]} is not a supported host" }, status: :bad_request unless supported_host_types.include?(repo_host_and_name[:host_type].downcase)

      Repository.create_from_host(repo_host_and_name[:host_type], repo_host_and_name[:full_name], auth_token.token)
    end

    # compact repos array to remove any invalid/not found repositories
    repos.compact.each do |repo|
      repo.gather_maintenance_stats_async(priority: :medium) unless repo.repository_maintenance_stats.exists?
    end

    head :accepted
  end

  def begin_project_watch(project)
    project.update_maintenance_stats_async(priority: :high) unless project.repository_maintenance_stats.exists?
  end
end
