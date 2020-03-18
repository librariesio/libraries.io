# frozen_string_literal: true

class Identity < ApplicationRecord
  belongs_to :user
  belongs_to :repository_user
  validates_presence_of :uid, :provider

  VIEWABLE_PROVIDERS = %w[github gitlab bitbucket].freeze

  scope :viewable, -> { where(provider: VIEWABLE_PROVIDERS) }

  def to_param
    {
      host_type: provider.downcase,
      login: nickname,
    }
  end

  def self.find_with_omniauth(auth)
    find_by(uid: auth["uid"], provider: auth["provider"])
  end

  def self.create_with_omniauth(auth)
    create(uid: auth["uid"], provider: auth["provider"])
  end

  def update_from_auth_hash(auth_hash)
    self.token = auth_hash.fetch("credentials", {}).fetch("token")

    case auth_hash["provider"]
    when "github", "githubpublic", "githubprivate"
      self.nickname   = auth_hash.fetch("info", {}).fetch("nickname")
      self.avatar_url = "https://avatars1.githubusercontent.com/u/#{uid}"
    when "gitlab"
      self.nickname   = auth_hash.fetch("info", {}).fetch("username")
      self.avatar_url = auth_hash.fetch("info", {}).fetch("image")
    when "bitbucket"
      self.nickname   = uid
      self.avatar_url = auth_hash.fetch("info", {}).fetch("avatar")
    end

    save
  end

  def avatar_url(size = 60)
    avatar = read_attribute(:avatar_url)
    case provider
    when "github", "githubpublic", "githubprivate"
      "#{avatar}?size=#{size}"
    when "gitlab"
      avatar
    when "bitbucket"
      avatar.gsub("/32/", "/#{size}/")
    end
  end
end
