# frozen_string_literal: true

module GithubGraphql
  class Response
    attr_reader :data, :status_code, :headers, :errors

    # @param graphql_response [GraphQL::Client::Response] Response object from query
    def initialize(graphql_response)
      @headers = graphql_response.original_hash.fetch("headers")
      @status_code = graphql_response.original_hash.fetch("status_code")

      @data = graphql_response.data
      @errors = graphql_response.errors
    end

    # Try extracting a nested value from the data
    # @param keys [*String] list of keys to dig through
    def dig_data(*keys)
      data.to_h.dig(*keys)
    end

    def unauthorized?
      status_code == "401"
    end

    def rate_limited?
      headers["x-ratelimit-remaining"].to_s == "0"
    end
  end
end
