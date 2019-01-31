module MaintenanceStats
  module Queries
    class RepositoryContributorStatsQuery < BaseQuery
      @@valid_params = [:full_name]
      @@required_params = [:full_name]
      @@retry_amount = 4
      def self.client_type
        :v3
      end
      def query(params: {}, count: 0)
        raise Octokit::Error.new "Didn't get a response after #{@@retry_amount} attempts" if params[:count].present? && params[:count] >= @@retry_amount
        validate_params(params)

        resp = @client.contributor_stats(params[:full_name])
        if @client.last_response.status == 202
          sleep 1
          return query(params: params, count: count+=1)
        end
        resp
      end
    end
  end
end
