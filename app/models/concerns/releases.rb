# frozen_string_literal: true

module Releases
  def stable_releases
    versions.select(&:stable?)
  end

  def prereleases
    versions.select(&:prerelease?)
  end

  def latest_stable_version
    return @latest_stable_version if @latest_stable_version.present?

    @latest_stable_version = if stable_releases.any? { |r| r.published_at.present? }
                               stable_releases.max_by(&:published_at)
                             else
                               stable_releases.sort
                             end
  end

  def latest_stable_tag
    return nil if repository.nil?

    return @latest_stable_tag if @latest_stable_tag.present?

    stable_tags = tags.published.select(&:stable?)

    @latest_stable_tag = if stable_tags.any? { |r| r.published_at.present? }
                           stable_tags.max_by(&:published_at)
                         else
                           stable_tags.sort
                         end
  end

  def latest_stable_release
    latest_stable_version || latest_stable_tag
  end

  def latest_version
    versions.order("published_at DESC NULLS LAST", created_at: :desc).first
  end

  def latest_tag
    return nil if repository.nil?

    tags.published.order("published_at DESC NULLS LAST", created_at: :desc).first
  end

  def latest_release
    latest_version || latest_tag
  end

  def first_version
    @first_version ||= versions.order("published_at ASC NULLS LAST", :created_at).first
  end

  def first_tag
    return nil if repository.nil?

    tags.published.order("published_at ASC NULLS LAST", :created_at).first
  end

  def first_release
    first_version || first_tag
  end

  def latest_release_published_at
    read_attribute(:latest_release_published_at) || (latest_release.try(:published_at).presence || updated_at)
  end

  def set_latest_release_published_at
    self.latest_release_published_at = (latest_release.try(:published_at).presence || updated_at)
  end

  def set_latest_release_number
    self.latest_release_number = latest_release.try(:number)
  end

  def set_latest_stable_release_info
    latest_stable = latest_stable_release
    self.latest_stable_release_number = latest_stable.try(:number)
    self.latest_stable_release_published_at = (latest_stable.try(:published_at).presence || latest_stable.try(:updated_at))
  end

  def set_runtime_dependencies_count
    self.runtime_dependencies_count = latest_release.try(:runtime_dependencies_count)
  end
end
