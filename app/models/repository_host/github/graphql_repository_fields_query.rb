# frozen_string_literal: true

module RepositoryHost
  class Github
    class GraphqlRepositoryFieldsQuery
      class QueryError < StandardError; end

      VALID_PARAMS = %i[owner repository_name].freeze
      REQUIRED_PARAMS = %i[owner repository_name].freeze

      QUERY = GithubGraphql.parse_query <<-GRAPHQL
          query($owner: String!, $repository_name: String!){
            repository(owner: $owner, name: $repository_name){
              codeOfConduct {
                url
              }
              contributingGuidelines {
                url
              }
              securityPolicyUrl
              fundingLinks {
                url
              }
            }
          }
      GRAPHQL

      def initialize(client)
        @client = client
      end

      def query(params: {})
        raise "Invalid parameters #{params} sent to #{name}" unless validate_params(params)

        full_name = [params[:owner], params[:repository_name]].join("/")

        results = @client.query(QUERY, variables: params)
        check_for_graphql_errors(results, full_name)

        extract_results(results)
      end

      private

      def extract_results(results)
        results = results.data.to_h

        {
          code_of_conduct_url: results.dig("repository", "codeOfConduct", "url"),
          contributing_guidelines_url: results.dig("repository", "contributingGuidelines", "url"),
          funding_urls: results.dig("repository", "fundingLinks")&.map { |funding_link| funding_link["url"] },
        }
      end

      def validate_params(params)
        REQUIRED_PARAMS.each do |key|
          return false unless params.include? key
        end

        params.each do |key, _|
          return false unless VALID_PARAMS.include? key
        end
        true
      end

      def check_for_graphql_errors(result, repository_name)
        if result.errors.any?
          error_messages = result.errors.values.flatten
          StructuredLog.capture(
            "GITHUB_REPOSITORY_GRAPHQL_FIELDS",
            {
              repository_name: repository_name,
              error_messages: error_messages,
            }
          )
          raise QueryError, "Error exists in query: #{error_messages}"
        end

        if result.data.nil?
          StructuredLog.capture(
            "GITHUB_REPOSITORY_GRAPHQL_FIELDS",
            {
              repository_name: repository_name,
              error_messages: ["no data found in result"],
            }
          )
          raise QueryError, "No data found in result"
        end

        if result.data.errors.any?
          error_messages = result.data.errors.values.flatten
          StructuredLog.capture(
            "GITHUB_REPOSITORY_GRAPHQL_FIELDS",
            {
              repository_name: repository_name,
              error_messages: error_messages,
            }
          )
          raise QueryError, "Error exists in result: #{error_messages}"
        end
      end
    end
  end
end
