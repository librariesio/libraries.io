# frozen_string_literal: true

# NOTE: This is _not_ an active model serializer. To use, instantiate and
# call #serialize
#
# @param [Boolean] internal_key is the caller coming from an internal ApiKey?
class OptimizedProjectSerializer
  PROJECT_ATTRIBUTES = %w[
    dependent_repos_count
    dependents_count
    deprecation_reason
    description
    homepage
    language
    last_synced_at
    latest_release_number
    latest_release_published_at
    latest_stable_release_number
    latest_stable_release_published_at
    license_normalized
    license_set_by_admin
    licenses
    normalized_licenses
    platform
    rank
    repository_url
    status
  ].freeze

  VERSION_ATTRIBUTES = %i[number published_at original_license status repository_sources].freeze

  def initialize(projects, requested_name_map, internal_key: false)
    @projects = projects
    @requested_name_map = requested_name_map
    @internal_key = internal_key
  end

  def serialize
    Datadog::Tracing.trace("optimized_project_serializer#serialize") do |_span, _trace|
      @projects.map do |project|
        serialize_project(project)
      end
    end
  end

  def serialize_project(project)
    Datadog::Tracing.trace("optimized_project_serializer#serialize_project") do |_span, _trace|
      project
        .attributes
        .slice(*PROJECT_ATTRIBUTES)
        .merge!(
          keywords: project.keywords.join(","), # the method, not the db field
          canonical_name: project.name,
          name: @requested_name_map[[project.platform, project.name]],
          download_url: project.download_url,
          forks: project.forks,
          latest_download_url: project.latest_download_url,
          package_manager_url: project.package_manager_url,
          repository_license: project.repository_license,
          repository_status: project.repository_status,
          stars: project.stars,
          versions: versions_by_project_id.fetch(project.id, []),
          contributions_count: project.contributions_count,
          code_of_conduct_url: project.code_of_conduct_url,
          contribution_guidelines_url: project.contribution_guidelines_url,
          funding_urls: project.funding_urls,
          security_policy_url: project.security_policy_url
        ).tap do |result|
          if @internal_key
            result[:updated_at] = project.updated_at
            result[:repository_maintenance_stats] = maintenance_stats[project.repository_id]
          end
        end
    end
  end

  def maintenance_stats
    @maintenance_stats ||= Datadog::Tracing.trace("optimized_project_serializer#maintenance_stats") do |_span, _trace|
      RepositoryMaintenanceStat
        .where(repository_id: @projects.map { |p| p.repository&.id }.compact)
        .pluck(*RepositoryMaintenanceStat::API_FIELDS, :repository_id)
        .each_with_object(Hash.new { |h, k| h[k] = [] }) do |row, stats|
          stats[row[-1]] << RepositoryMaintenanceStat::API_FIELDS.zip(row).to_h
        end
    end
  end

  def versions_by_project_id
    @versions_by_project_id ||= Version
      .where(project_id: @projects.map(&:id))
      .pluck(:project_id, :created_at, *VERSION_ATTRIBUTES)
      .group_by(&:first)
      .transform_values do |versions_values|
        versions_values.map do |version_values|
          # turn Arrays into attribute Hashes, sans "id"
          attrs = VERSION_ATTRIBUTES.zip(version_values[2..]).to_h

          # Version model falls back published_at to created_at
          attrs[:published_at] ||= version_values[1]

          attrs
        end
      end
  end
end
