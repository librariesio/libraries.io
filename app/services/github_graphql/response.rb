# frozen_string_literal: true

module GithubGraphql
  class Response
    def initialize(graphql_response)
      @graphql_response = graphql_response
    end

    delegate :data, :errors, to: :@graphql_response

    # Try extracting a nested value from the data
    # @param keys [*String] list of keys to dig through
    def dig(*keys)
      data.to_h[keys]
    end

    # @return [Array<String>] Collection of returned error messages, if any
    def error_messages
      Array.wrap(errors&.messages&.values)
    end

    def errors?
      errors.any? || data.errors.any?
    end

    # Checks if the response contains an authorization error
    def unauthorized?
      error_messages.any? { |msg| msg.start_with?("401") }
    end

    # Checks if the response contains a rate limit exhausted error
    def rate_limited?
      error_messages.any? { |msg| msg.start_with?("idkyet") }
    end
  end
end
