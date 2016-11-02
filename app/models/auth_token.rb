class AuthToken < ApplicationRecord
  validates_presence_of :token

  def self.client(options = {})
    if @auth_token && @auth_token.high_rate_limit?
      return @auth_token.github_client(options)
    end
    auth_token = order("RANDOM()").limit(100).sample
    if auth_token.high_rate_limit?
      @auth_token = auth_token
      return auth_token.github_client(options)
    end
    client
  end

  def self.token
    client.access_token
  end

  def self.create_multiple(array_of_tokens)
    array_of_tokens.each do |token|
      self.find_or_create_by(token: token)
    end
  end

  def high_rate_limit?
    github_client.rate_limit.remaining > 500
  rescue Octokit::Unauthorized
    false
  end

  def github_client(options = {})
    AuthToken.new_client(token, options)
  end

  def self.fallback_client(token = nil)
    AuthToken.new_client(token)
  end

  def self.new_client(token, options = {})
    token ||= AuthToken.token
    Octokit::Client.new({access_token: token, auto_paginate: true}.merge(options))
  end
end
