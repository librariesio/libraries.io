module SourceRank
  extend ActiveSupport::Concern

  def rank
    r = 0
    # basic information available
    r +=1 if basic_info_present?

    # repo present
    r +=1 if repository_present?

    # valid license present
    r +=1 if license_present?

    # more than one version
    r +=1 if versions_present?

    # a version released within the last X months
    r +=1 if recent_release?

    # at least X months old
    r +=1 if not_brand_new?

    # number of github stars
    r += log_scale(stars)

    # number of dependent projects
    r += log_scale(dependents.count)

    # number of contributors
    r += log_scale(github_contributions.length)

    # more than one maintainer/owner

    # number of downloads

    return r
  end

  def basic_info_present?
    [description.presence, homepage.presence, repository_url.presence, keywords.presence].compact.length > 1
  end

  def repository_present?
    github_repository.present?
  end

  def license_present?
    normalized_licenses.present?
  end

  def versions_present?
    versions.length > 1
  end

  def recent_release?
    versions.any? {|v| v.published_at && v.published_at > 6.months.ago }
  end

  def not_brand_new?
    versions.any? {|v| v.published_at && v.published_at > 6.months.ago }
  end

  def log_scale(number)
    return 0 if number <= 0
    Math.log10(number).round
  end
end
