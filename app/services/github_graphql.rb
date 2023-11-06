# frozen_string_literal: true

require "graphql/client"
require "graphql/client/http"

module GithubGraphql
  # The request failed. Check messages for details
  class RequestError < RuntimeError; end
  # The request failed because the user's rate limit was exahusted
  class RateLimitError < RequestError; end
  # The request failed because the token failed to authorize it
  class AuthorizationError < RequestError; end

  GRAPHQL_ENDPOINT = "https://api.github.com/graphql"

  HttpAdapter = ::GraphQL::Client::HTTP.new(GRAPHQL_ENDPOINT) do
    def headers(context)
      token = context[:access_token]
      raise "Missing Github access token" unless token.present?

      { "Authorization" => "Bearer #{token}" }
    end
  end

  ApiClient = ::GraphQL::Client.new(
    schema: Rails.application.config.graphql.schema,
    execute: HttpAdapter
  )

  # Prepare a static query from given string
  def self.parse_query(query_string)
    ApiClient.parse(query_string)
  end

  # @param token [String] A Github API token
  def self.new_client(token)
    Client.new(token)
  end

  # Returns true if the user has more than our minimum threshold of credit
  def self.not_low_rate_remaining?(token)
    rate_limit_remaining(token) < LOW_RATE_REMAINING_THRESHOLD
  end

  # @param token [String] A Github API token
  # @raise [AuthorizationError]
  # @return [Integer] The user's remaining rate limit credit
  def self.rate_limit_remaining(token)
    response = new_client(token).query!(REMAINING_RATE_LIMIT_QUERY)

    response.data.rate_limit.remaining
  rescue RateLimitError
    0
  end

  REMAINING_RATE_LIMIT_QUERY = parse_query <<-GRAPHQL
    query {
      viewer {
        login
      }
      rateLimit {
        remaining
      }
    }
  GRAPHQL
end
