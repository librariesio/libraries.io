# frozen_string_literal: true

module MaintenanceStats
  module Queries
    class QueryUtils
      class QueryError < StandardError; end

      def self.check_for_graphql_errors(result, repository_name)
        if result.errors.any?
          error_messages = result.errors.values.flatten
          StructuredLog.capture(
            "GITHUB_STAT_QUERY_ERROR",
            {
              repository_name: repository_name,
              error_messages: error_messages,
            }
          )
          raise QueryError, "Error exists in query: #{error_messages}"
        end

        if result.data.nil?
          StructuredLog.capture(
            "GITHUB_STAT_QUERY_ERROR",
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
            "GITHUB_STAT_QUERY_ERROR",
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
