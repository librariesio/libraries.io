# frozen_string_literal: true
module MaintenanceStats
  module Queries
    module Github
      class RepositoryContributorStatsQuery < BaseQuery
        VALID_PARAMS = [:full_name]
        REQUIRED_PARAMS = [:full_name]

        def self.client_type
          :v3
        end

        def query(params: {})
          validate_params(params)

          @client.contributor_stats(params[:full_name], retry_wait: 0.5, retry_timeout: 10)
        end
      end
    end
  end
end
