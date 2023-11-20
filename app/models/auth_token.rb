# frozen_string_literal: true

# == Schema Information
#
# Table name: auth_tokens
#
#  id         :integer          not null, primary key
#  authorized :boolean
#  login      :string
#  token      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class AuthToken < ApplicationRecord
  validates_presence_of :token
  scope :authorized, -> { where(authorized: [true, nil]) }

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
    token ||= AuthToken.token
    http_adapter = GraphQL::Client::HTTP.new("https://api.github.com/graphql") do
      attr_accessor :token

      # rubocop: disable Lint/NestedMethodDefinition:
      def headers(_context)
        { "Authorization" => "bearer #{token}" }
      end
      # rubocop: enable Lint/NestedMethodDefinition:
    end

    http_adapter.token = token

    # create new client with HTTP adapter set to use token and the loaded GraphQL schema
    GraphQL::Client.new(schema: Rails.application.config.graphql.schema, execute: http_adapter)
  end

  def self.find_token(api_version, retries: 0)
    auth_token = authorized.order(Arel.sql("RANDOM()")).first
    return auth_token if auth_token.safe_to_use?(api_version)

    retries += 1
    raise "No Authorized AuthToken Could Be Found!" if retries >= 10

    find_token(api_version, retries: retries)
  end
end
