require "graphql/client/http"

class AuthToken < ApplicationRecord
  validates_presence_of :token
  scope :authorized, -> { where(authorized: [true, nil]) }

  def self.client(options = {})
    if @auth_token && @auth_token.high_rate_limit?
      return @auth_token.github_client(options)
    end
    auth_token = authorized.order("RANDOM()").limit(100).sample
    if auth_token.high_rate_limit?
      @auth_token = auth_token
      return auth_token.github_client(options)
    end
    client
  end

  def self.v4_client
    if @auth_token && @auth_token.high_rate_limit?
      return @auth_token.v4_github_client
    end
    auth_token = authorized.order("RANDOM()").limit(100).sample
    if auth_token.high_rate_limit?
      @auth_token = auth_token
      return auth_token.v4_github_client
    end
    v4_client
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
  rescue Octokit::Unauthorized, Octokit::AccountSuspended
    false
  end

  def still_authorized?
    !!github_client.rate_limit
  rescue Octokit::Unauthorized, Octokit::AccountSuspended
    false
  end

  def github_client(options = {})
    AuthToken.new_client(token, options)
  end

  def v4_github_client
    AuthToken.new_v4_client(token)
  end

  def self.fallback_client(token = nil)
    AuthToken.new_client(token)
  end

  def self.new_client(token, options = {})
    token ||= AuthToken.token
    Octokit::Client.new({access_token: token, auto_paginate: true}.merge(options))
  end

  def self.new_v4_client(token)
    token ||= AuthToken.token
    http_adapter = GraphQL::Client::HTTP.new("https://api.github.com/graphql") do
      @@token = token
      
      def headers(context)
        puts "Here's your f'in token!!!!! #{@@token}"
          {
          "Authorization" => "Bearer #{@@token}"
          }
      end
    end

    # Fetch latest schema on init, this will make a network request
    schema = GraphQL::Client.load_schema(http_adapter)
  
    GraphQL::Client.new(schema: schema, execute: http_adapter)
  end
end
