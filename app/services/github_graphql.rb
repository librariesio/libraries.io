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
  SCHEMA_DUMP_PATH = "config/github_graphql_schema.json"

  HTTP = ::GraphQL::Client::HTTP.new(GRAPHQL_ENDPOINT) do
    def headers(context)
      token = context[:access_token]
      raise "Missing Github access token" unless token.present?

      { "Authorization" => "Bearer #{token}" }
    end
  end

  Schema = ::GraphQL::Client.load_schema(SCHEMA_DUMP_PATH)

  ApiClient = ::GraphQL::Client.new(
    schema: Schema,
    execute: HTTP
  )

  # Prepare a static query from given string
  def self.parse_query(query_string)
    ApiClient.parse(query_string)
  end

  # @param token [String] A Github API token
  def self.new_client(token)
    Client.new(token)
  end

  def self.refresh_dump!(token)
    GraphQL::Client.dump_schema(HTTP, SCHEMA_DUMP_PATH, context: { access_token: token })
  end
end
