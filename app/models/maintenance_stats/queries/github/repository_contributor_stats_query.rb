# frozen_string_literal: true
module MaintenanceStats
  module Queries
    module Github
      class RepositoryContributorStatsQuery < BaseQuery
        VALID_PARAMS = [:full_name]
        REQUIRED_PARAMS = [:full_name]
        TIMEOUT_SEC = 10

        def self.client_type
          :v3
        end

        def query(params: {})
          validate_params(params)
          full_name = params[:full_name]

          result = @client.contributor_stats(full_name, retry_timeout: TIMEOUT_SEC)

          raise Octokit::Error, { body: "Could not fetch contributor stats for #{full_name}" } if result.nil?

          result
        end
      end
    end
  end
end
