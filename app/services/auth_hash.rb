class AuthHash
  def self.extract_user_info(hash)
    AuthHash.new(hash).user_info
  end

  def initialize(user_hash)
    @user_hash = user_hash
  end

  def user_info
    h = {
      token:       token,
      uid:         uid,
      nickname:    nickname,
      email:       email,
    }
    h.merge!(public_repo_token: public_repo_token) if public_repo_token.present?
    h.merge!(private_repo_token: private_repo_token) if private_repo_token.present?
    h
  end

  private

  attr_reader :user_hash

  def provider
    'github'
  end

  def uid
    user_hash.fetch('uid')
  end

  def nickname
    info.fetch('nickname')
  end

  def email
    info.fetch('email', nil)
  end

  def name
    raw_info.fetch('name', nil)
  end

  def token
    user_hash.fetch('credentials', {}).fetch('token') if user_hash.fetch('provider') == 'github'
  end

  def public_repo_token
    user_hash.fetch('credentials', {}).fetch('token') if user_hash.fetch('provider') == 'githubpublic'
  end

  def private_repo_token
    user_hash.fetch('credentials', {}).fetch('token') if user_hash.fetch('provider') == 'githubprivate'
  end

  private

  def info
    user_hash.fetch('info', {})
  end

  def raw_info
    user_hash.fetch('extra', {}).fetch('raw_info', {})
  end
end
