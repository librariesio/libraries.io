# frozen_string_literal: true

# == Schema Information
#
# Table name: auth_tokens
#
#  id         :integer          not null, primary key
#  authorized :boolean
#  login      :string
#  scopes     :string           default([]), is an Array
#  token      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class AuthToken < ApplicationRecord
  validates_presence_of :token
  scope :authorized, -> { where(authorized: [true, nil]) }
  # find tokens that include ANY of the scopes provided
  scope :has_scope, ->(searched_scopes) { where("scopes && array[?]::varchar[]", Array(searched_scopes)) }

  LOW_RATE_LIMIT_REMAINING_THRESHOLD = 500

  def self.client(options = {})
    find_token(:v3).github_client(options)
  end

  def self.v4_client
    find_token(:v4).v4_github_client
  end

  def self.token
    client.access_token
  end

  def self.create_multiple(array_of_tokens)
    array_of_tokens.each do |token|
      find_or_create_by(token: token)
    end
  end

  def fetch_resource_limits
    client = github_client

    v3_stat = client.rate_limit!.remaining
    v4_stat = client.last_response.data.resources.graphql.remaining

    {
      v3: v3_stat,
      v4: v4_stat,
    }
  end

  def safe_to_use?(api_version)
    resource_limits = fetch_resource_limits
    remaining = resource_limits.fetch(api_version)

    remaining > LOW_RATE_LIMIT_REMAINING_THRESHOLD
  rescue Octokit::Unauthorized, Octokit::AccountSuspended
    false
  rescue StandardError => e
    StructuredLog.capture(
      "FAILED_READING_GITHUB_RATE_LIMITS",
      { api_version: api_version, auth_token_id: id, remaining: remaining, error_class: e, error_message: e.message }
    )

    false
  end

  def still_authorized?
    !!github_client.rate_limit
  rescue Octokit::Unauthorized, Octokit::AccountSuspended
    false
  end

  def self.fetch_auth_scopes(token, github_response)
    unless github_response
      client = AuthToken.new_client(token)
      client.rate_limit!.remaining
      github_response = client.last_response
    end

    github_response.headers.fetch("x-oauth-scopes", "").split(", ")
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
    Octokit::Client.new({ access_token: token, auto_paginate: true }.merge(options))
  end

  def self.new_v4_client(token)
    token ||= AuthToken.find_token(:v4).token
    GithubGraphql.new_client(token)
  end

  def self.find_token(api_version, retries: 0, required_scope: [])
    query = authorized.order(Arel.sql("RANDOM()"))
    unless required_scope.blank?
      query = query.has_scope(required_scope)
    end
    auth_token = query.first
    return auth_token if auth_token.safe_to_use?(api_version)

    retries += 1
    raise "No Authorized AuthToken Could Be Found!" if retries >= 10

    find_token(api_version, retries: retries, required_scope: required_scope)
  end
end
