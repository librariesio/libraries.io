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

    github_lookup_names, other_lookup_names = lookup_names.partition { |repo_host_and_name| repo_host_and_name[:host_type].downcase == "github" }

    # grab a working token now so we don't run into issues trying to find one in the loop for each
    # repository name
    auth_token = AuthToken.find_token(:v3) if github_lookup_names.present?

    # do we really want to synchronously create and refresh these repos here?
    # Not sure this is the right choice.

    github_repos = github_lookup_names.map do |repo_host_and_name|
      Repository.create_from_host(repo_host_and_name[:host_type], repo_host_and_name[:full_name], auth_token.token)
    end

    other_repos = other_lookup_names.map do |repo_host_and_name|
      Repository.create_from_host(repo_host_and_name[:host_type], repo_host_and_name[:full_name], nil)
    end

    # compact repos array to remove any invalid/not found repositories
    repos = (github_repos + other_repos).compact

    repos.each do |repo|
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
