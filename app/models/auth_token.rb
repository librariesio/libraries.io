class AuthToken < ActiveRecord::Base
  def self.client
    if @auth_token && @auth_token.high_rate_limit?
      return @auth_token.github_client
    end
    auth_token = limit(50).sample
    if auth_token.high_rate_limit?
      @auth_token = auth_token
      return auth_token.github_client
    end
    client
  end

  def self.create_multiple(array_of_tokens)
    array_of_tokens.each do |token|
      self.find_or_create_by(token: token)
    end
  end

  def high_rate_limit?
    github_client.rate_limit.remaining > 100
  rescue Octokit::Unauthorized
    false
  end

  def github_client
    Octokit::Client.new(access_token: token, auto_paginate: true)
  end
end
