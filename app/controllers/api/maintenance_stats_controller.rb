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

  # A possible roadmap for the future is to replace this endpoint with a "track_repository" that:
  #  - creates the repository if we haven't (so we don't have to track everything just in case)
  #  - marks it interesting, even if it isn't github
  #  - starts watching maint stats if supported (if it is github, for now)
  def begin_watching_repositories
    lookup_names = params.require(:repositories).map { |p| p.permit(%i[host_type full_name]).to_h.symbolize_keys }

    auth_token = nil
    repos = lookup_names.map do |repo_host_and_name|
      # the create_from_host below does a remote API call to refresh the repo and THEN looks for an
      # existing repo; we look for existing here first to save some time.
      existing_repo = Repository::PersistRepositoryFromUpstream
        .find_repository_from_host_type_and_full_name(host_type: repo_host_and_name[:host_type],
                                                      full_name: repo_host_and_name[:full_name])

      existing_repo || begin
        is_github = repo_host_and_name[:host_type].downcase == "github"
        auth_token ||= AuthToken.find_token(:v3) if is_github
        Repository.create_from_host(repo_host_and_name[:host_type], repo_host_and_name[:full_name],
                                    is_github ? auth_token.token : nil)
      end
    end

    # compact repos array to remove any invalid/not found repositories
    repos.compact.each do |repo|
      # mark it as now interesting; someday we may make a dedicated endpoint for this.
      # We use update_column here to avoid any callbacks/validation since none of those
      # should care about the interesting flag.
      repo.update_column(:interesting, true)
      # for now, only github supports maint stats
      if repo.host_type.downcase == "github" && !repo.repository_maintenance_stats.exists?
        repo.gather_maintenance_stats_async(priority: :medium)
      end
    end

    head :accepted
  end

  def begin_project_watch(project)
    project.repository&.update_column(:interesting, true)
    project.update_maintenance_stats_async(priority: :high) unless project.repository_maintenance_stats.exists?
  end
end
