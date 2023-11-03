# frozen_string_literal: true

module GithubGraphql
  class Client
    # @param token [String] A github api token
    def initialize(token)
      @token = token
    end

    # @param See {#query}
    # @return [Response]
    def query!(*args)
      response = query(args)

      if response.unauthorized?
        raise AuthorizationError, response.error_messages
      elsif response.rate_limited?
        raise RateLimitError, response.error_messages
      elsif response.errors?
        raise RequestError, response.error_messages
      end

      response
    end

    # @param parsed_query A parsed GraphQL query (See GithubGraphql#parse_query)
    # @param variables [Hash] hash of variables to use for query
    # @param context [Hash] hash of any additional request-time params to the request adapter.
    #  Token is already included.
    # @return [Response]
    def query(parsed_query, variables: {}, context: {})
      result = ApiClient.query(
        parsed_query,
        context: context.with_defaults(access_token: @token),
        variables: variables
      )

      response = Response.new(result)

      StructuredLog.capture(
        "UPSTREAM_QUERY_SENT",
        {
          upstream_service: "github_graphql",
          query_name: parsed_query.name.camelize,
          success: !response.errors?,
          unauthorized: response.unauthorized?,
          rate_limited: response.rate_limited?,
          error_message: response.error_messages.join,
        }
      )

      response
    end
  end
end
