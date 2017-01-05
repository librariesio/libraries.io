class Identity < ApplicationRecord
  belongs_to :user
  validates_presence_of :uid, :provider

  def self.find_with_omniauth(auth)
    find_by(uid: auth['uid'], provider: auth['provider'])
  end

  def self.create_with_omniauth(auth)
    create(uid: auth['uid'], provider: auth['provider'])
  end

  def find_existing_user
    return nil unless provider =~ /github/
    User.find_by_uid(uid)
  end

  def update_from_auth_hash(auth_hash)
    self.token = auth_hash.fetch('credentials', {}).fetch('token')

    case auth_hash['provider']
    when 'github'
      self.nickname   = auth_hash.fetch('info', {}).fetch('nickname')
      self.avatar_url = "https://avatars1.githubusercontent.com/u/#{self.uid}?v=3"
    when 'gitlab'
      self.nickname   = auth_hash.fetch('info', {}).fetch('username')
      self.avatar_url = auth_hash.fetch('info', {}).fetch('image')
    when 'bitbucket'
      self.nickname   = self.uid
      self.avatar_url = auth_hash.fetch('info', {}).fetch('avatar')
    end

    self.save
  end

  def avatar_url(size = 60)
    avatar = read_attribute(:avatar_url)
    case provider
    when 'github', 'githubpublic', 'githubprivate'
      avatar + "?size=#{size}"
    when 'gitlab'
      avatar
    when 'bitbucket'
      avatar.gsub('/32/', "/#{size}/")
    end
  end
end
