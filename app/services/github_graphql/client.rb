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
        raise AuthorizationError
      elsif response.rate_limited?
        raise RateLimitError
      elsif response.errors?
        raise RequestError
      end

      response
    end

    # @param parsed_query A parsed GraphQL query (See GithubGraphql#parse_query)
    # @param variables [Hash] hash of variables to use for query
    # @param context [Hash] hash of any additional request-time params to the request adapter.
    #  Token is already included.
    # @return [Response]
    def query(parsed_query, variables: {}, context: {})
      graphql_response = ApiClient.query(
        parsed_query,
        context: context.with_defaults(access_token: @token),
        variables: variables
      )

      Response.new(graphql_response)
    end
  end
end
