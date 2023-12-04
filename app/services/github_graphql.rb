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
    # @param context [Hash] Values needed to build headers for all requests
    # @option context [String] :access_token Github access token
    def headers(context)
      token = context[:access_token]
      raise "Missing Github access token" unless token.present?

      { "Authorization" => "Bearer #{token}" }
    end

    # Override upstream implementation to include needed response metadata
    def execute(document:, operation_name: nil, variables: {}, context: {})
      # Build request like upstream
      # https://github.com/github/graphql-client/blob/master/lib/graphql/client/http.rb#L58
      request = Net::HTTP::Post.new(uri.request_uri)

      request.basic_auth(uri.user, uri.password) if uri.user || uri.password

      request["Accept"] = "application/json"
      request["Content-Type"] = "application/json"
      headers(context).each { |name, value| request[name] = value }

      body = {}
      body["query"] = document.to_query_string
      body["variables"] = variables if variables.any?
      body["operationName"] = operation_name if operation_name
      request.body = JSON.generate(body)

      response = connection.request(request)

      # Customization begins here
      # Capture headers and status code from http response to better detect error states
      response_meta = {
        "headers" => response.each_header.to_h,
        "status_code" => response.code,
      }

      case response
      when Net::HTTPOK, Net::HTTPBadRequest
        # Return response details & results body
        response_meta.merge(
          JSON.parse(response.body)
        )
      else
        response_meta.merge(
          { "errors" => [{ "message" => "#{response.code} #{response.message}" }] }
        )
      end
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

  # Update local cache of Github GraphQL API Schema
  # @param token [String] A Github API token
  # @param destination [String] Relative file path for output
  def self.refresh_dump!(token:, destination: SCHEMA_DUMP_PATH)
    ::GraphQL::Client.dump_schema(HTTP, destination, context: { access_token: token })
  end
end
