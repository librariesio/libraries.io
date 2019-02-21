module MaintenanceStats
  module Queries
    class IssuesQuery < BaseQuery
      @@valid_params = [:full_name, :since]
      @@required_params = [:full_name, :since]
      @@retry_amount = 4
      def self.client_type
        :v3
      end

      def run_query(page, per_page, params, count: 0)
        raise Octokit::Error.new "Didn't get a response after #{@@retry_amount} attempts" if params[:count].present? && params[:count] >= @@retry_amount

        resp = @client.list_issues(params[:full_name], page: page, per_page: per_page, query: {state: "all", since: params[:since]})
        if @client.last_response.status == 202
          sleep 1
          return query(params: params, count: count+=1)
        end
        resp
      end

      def query(params: {}, max_pages: 10)
        validate_params(params)

        issues = []
        curr_page = 1
        has_next = true
        while curr_page <= max_pages && has_next
          resp = run_query(curr_page, 100, params)
          issues = issues.concat(resp)
          curr_page+=1
          has_next = !@client.last_response.rels[:next].nil?
        end

        {
          issues: issues,
          truncated: has_next
        }
      end
    end
  end
end
