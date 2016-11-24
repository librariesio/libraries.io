module SourceRank
  extend ActiveSupport::Concern

  def update_source_rank
    update_column :rank, source_rank
    touch
    __elasticsearch__.index_document
  end

  def update_source_rank_async
    UpdateSourceRankWorker.perform_async(self.id) if updated_at.present? && updated_at < 1.day.ago
  end

  def set_source_rank
    self.rank = source_rank
  end

  def source_rank
    source_rank_breakdown.values.sum > 0 ? source_rank_breakdown.values.sum : 0
  end

  def source_rank_breakdown
    @source_rank_breakdown ||= {
      basic_info_present:         basic_info_present? ? 1 : 0,
      repository_present:         repository_present? ? 1 : 0,
      readme_present:             readme_present? ? 1 : 0,
      license_present:            license_present? ? 1 : 0,
      versions_present:           versions_present? ? 1 : 0,
      follows_semver:             follows_semver? ? 1 : 0,
      recent_release:             recent_release? ? 1 : 0,
      not_brand_new:              not_brand_new? ? 1 : 0,
      one_point_oh:               one_point_oh? ? 1 : 0,
      dependent_projects:         log_scale(dependents_count) * 2,
      dependent_repositories:     log_scale(dependent_repos_count),
      github_stars:               log_scale(stars),
      contributors:               (log_scale(github_contributions_count) / 2.0).ceil,
      subscribers:                (log_scale(subscriptions.length) / 2.0).ceil,
      all_prereleases:            all_prereleases? ? -2 : 0,
      any_outdated_dependencies:  any_outdated_dependencies? ? -1 : 0,
      is_deprecated:              is_deprecated? ? -5 : 0,
      is_unmaintained:            is_unmaintained? ? -5 : 0,
      is_removed:                 is_removed? ? -5 : 0
    }
  end

  def basic_info_present?
    [description.presence, homepage.presence, repository_url.presence, keywords_array.presence].compact.length > 1
  end

  def repository_present?
    github_repository.present?
  end

  def readme_present?
    github_repository.present? && github_repository.readme.present?
  end

  def license_present?
    normalized_licenses.present?
  end

  def versions_present?
    versions_count > 1 || (github_tags.published.length > 0)
  end

  def recent_release?
    versions.any? {|v| v.published_at && v.published_at > 6.months.ago } ||
      (github_tags.published.any? {|v| v.published_at && v.published_at > 6.months.ago })
  end

  def not_brand_new?
    versions.any? {|v| v.published_at && v.published_at < 6.months.ago } ||
      (github_tags.published.any? {|v| v.published_at && v.published_at < 6.months.ago })
  end

  def any_outdated_dependencies?
    latest_version.try(:any_outdated_dependencies?)
  end

  def all_prereleases?
    prereleases.size == versions.size
  end

  def one_point_oh?
    versions.any?(&:greater_than_1?)
  end

  def log_scale(number)
    return 0 if number <= 0
    Math.log10(number).round
  end
end
