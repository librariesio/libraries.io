# frozen_string_literal: true
module MaintenanceStats
  module Queries
    module Github
      class RepositoryContributorStatsQuery < BaseQuery
        VALID_PARAMS = [:full_name]
        REQUIRED_PARAMS = [:full_name]
        RETRY_AMOUNT = 4

        def self.client_type
          :v3
        end

        def query(params: {}, count: 0)
          raise Octokit::Error.new "Didn't get a response after #{RETRY_AMOUNT} attempts" if params[:count].present? && params[:count] >= RETRY_AMOUNT
          validate_params(params)

          resp = @client.contributor_stats(params[:full_name])
          if @client.last_response.status == 202
            sleep (count + 1) * 0.5
            return query(params: params, count: count+=1)
          end
          resp
        end
      end
    end
  end
end
