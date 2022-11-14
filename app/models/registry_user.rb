# frozen_string_literal: true

# == Schema Information
#
# Table name: registry_users
#
#  id       :integer          not null, primary key
#  email    :string
#  login    :string
#  name     :string
#  platform :string
#  url      :string
#  uuid     :string
#
# Indexes
#
#  index_registry_users_on_platform_and_uuid  (platform,uuid) UNIQUE
#
class RegistryUser < ApplicationRecord
  has_many :registry_permissions
  has_many :projects, through: :registry_permissions

  def platform_class
    "PackageManager::#{platform}".constantize
  end

  def avatar_url(size = 60)
    return gravatar_url(size) if email.present?
    return github_avatar_url(size) if github_url.present?
    fallback_avatar_url(size)
  end

  def gravatar_url(size = 60)
    return nil unless email.present?
    hash = Digest::MD5.hexdigest(email.downcase)
    "https://www.gravatar.com/avatar/#{hash}?s=#{size}&d=retro"
  end

  def github_avatar_url(size)
    return nil unless github_url.present?
    "#{github_url}.png?s=#{size}"
  end

  def fallback_avatar_url(size = 60)
    hash = Digest::MD5.hexdigest("#{platform}-#{id}")
    "https://www.gravatar.com/avatar/#{hash}?s=#{size}&f=y&d=retro"
  end

  def on_github?
    github_url.present?
  end

  def github_url
    GithubURLParser.parse_to_full_user_url(url)
  end

  def profile_url
    return nil if login.nil?
    platform_class.registry_user_url(login)
  end

  def to_s
    name || login || ''
  end
end
