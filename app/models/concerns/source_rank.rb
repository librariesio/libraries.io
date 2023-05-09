# frozen_string_literal: true

module SourceRank
  extend ActiveSupport::Concern

  def update_source_rank
    self.rank = source_rank
    save if changed?
  end

  def update_source_rank_async
    UpdateSourceRankWorker.perform_async(id)

    ProjectScoreCalculationBatch.enqueue(platform, [id])
  end

  def set_source_rank
    self.rank = source_rank
  end

  def source_rank
    source_rank_breakdown.values.sum > 0 ? source_rank_breakdown.values.sum : 0
  end

  def source_rank_breakdown
    @source_rank_breakdown ||= {
      basic_info_present: basic_info_present? ? 1 : 0,
      repository_present: repository_present? ? 1 : 0,
      readme_present: readme_present? ? 1 : 0,
      license_present: license_present? ? 1 : 0,
      versions_present: multiple_versions_present? ? 1 : 0,
      follows_semver: follows_semver? ? 1 : 0,
      recent_release: recent_release? ? 1 : 0,
      not_brand_new: not_brand_new? ? 1 : 0,
      one_point_oh: one_point_oh? ? 1 : 0,
      dependent_projects: log_scale(dependents_count) * 2,
      dependent_repositories: log_scale(dependent_repos_count),
      stars: log_scale(stars),
      contributors: (log_scale(contributions_count) / 2.0).ceil,
      subscribers: (log_scale(subscriptions.length) / 2.0).ceil,
      all_prereleases: all_prereleases? ? -2 : 0,
      any_outdated_dependencies: any_outdated_dependencies? ? -1 : 0,
      is_deprecated: is_deprecated? ? -5 : 0,
      is_unmaintained: is_unmaintained? ? -5 : 0,
      is_removed: is_removed? ? -5 : 0,
    }
  end

  def basic_info_present?
    [description.presence, homepage.presence, repository_url.presence, keywords_array.presence].compact.length > 1
  end

  def repository_present?
    repository.present?
  end

  def readme_present?
    repository.present? && repository.readme.present?
  end

  def license_present?
    normalized_licenses.present?
  end

  def follows_semver?
    published_releases.all?(&:follows_semver?)
  end

  def uses_versions?
    versions_count > 0
  end

  def has_versions?
    versions_count > 1
  end

  def published_releases
    @published_releases ||= uses_versions? ? versions : tags.published
  end

  def multiple_versions_present?
    published_releases.length > 1
  end

  def any_versions?
    !published_releases.empty?
  end

  def recent_release?
    return false unless any_versions?

    published_releases.any? { |v| v.published_at && v.published_at > 6.months.ago }
  end

  def not_brand_new?
    return false unless any_versions?

    published_releases.any? { |v| v.published_at && v.published_at < 6.months.ago }
  end

  def any_outdated_dependencies?
    return false unless has_versions?

    latest_version.try(:any_outdated_dependencies?)
  end

  def all_prereleases?
    return false unless any_versions?

    published_releases.all?(&:prerelease?)
  end

  def one_point_oh?
    return false unless any_versions?

    published_releases.any?(&:greater_than_1?)
  end

  def log_scale(number)
    return 0 if number <= 0

    Math.log10(number).round
  end
end
