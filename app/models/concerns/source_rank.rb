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

    # a version released within the last X months
    r +=1 if recent_release?

    # at least X months old
    r +=1 if not_brand_new?

    r -=5 if is_deprecated?

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

  def log_scale(number)
    return 0 if number <= 0
    Math.log10(number).round
  end
end
