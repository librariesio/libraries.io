module MaintenanceStats
  module Queries
    class IssuesQuery < BaseQuery
      @@valid_params = [:full_name, :since]
      @@required_params = [:full_name, :since]
      @@retry_amount = 4
      def self.client_type
        :v3
      end
      def query(params: {}, count: 0)
        raise Octokit::Error.new "Didn't get a response after #{@@retry_amount} attempts" if params[:count].present? && params[:count] >= @@retry_amount
        validate_params(params)

        resp = @client.list_issues(params[:full_name], query: {state: "all", since: params[:since]})
        if @client.last_response.status == 202
          sleep 1
          return query(params: params, count: count+=1)
        end
        resp
      end
    end
  end
end
