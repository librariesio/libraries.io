module SourceRank
  extend ActiveSupport::Concern

  def update_source_rank
    update_column :rank, source_rank
    touch
  end

  def update_source_rank_async
    UpdateSourceRankWorker.perform_async(self.id)
  end

  def set_source_rank
    self.rank = source_rank
  end

  def source_rank
    r = 0
    # basic information available
    r +=1 if basic_info_present?

    # repo present
    r +=1 if repository_present?

    # readme present
    r +=1 if readme_present?

    # valid license present
    r +=1 if license_present?

    # more than one version
    r +=1 if versions_present?

    # all versions/tags are valid semver numbers
    r +=1 if follows_semver?

    # a version released within the last X months
    r +=1 if recent_release?

    # at least X months old
    r +=1 if not_brand_new?

    # has the project been marked as deprecated?
    r -=5 if is_deprecated?

    # has the project been marked as unmaintained?
    r -=5 if is_unmaintained?

    # has the project been marked as deprecated?
    r -=5 if is_removed?

    # does the latest version have any outdated dependencies
    r -=1 if any_outdated_dependencies?

    # any releases greater than or equal to 1.0.0
    r +=1 if one_point_oh?

    # every version is a prerelease?
    r -=2 if all_prereleases?

    # number of github stars
    r += log_scale(stars)

    # number of dependent projects
    r += log_scale(dependents_count) * 2

    # number of dependent repositories
    r += log_scale(dependent_repositories.open_source.length)

    # number of contributors
    r += (log_scale(github_contributions.length) / 2.0).ceil

    # number of subscribers
    r += (log_scale(subscriptions.length) / 2.0).ceil

    # more than one maintainer/owner?

    # number of downloads

    # documentation available?

    r = 0 if r < 0

    return r
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
    prereleases.length == versions.length
  end

  def one_point_oh?
    versions.any?(&:greater_than_1?)
  end

  def log_scale(number)
    return 0 if number <= 0
    Math.log10(number).round
  end
end
