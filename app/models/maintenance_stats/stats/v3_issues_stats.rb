module MaintenanceStats
  module Stats
    class V3IssueStats < BaseStat
      def count_issues(issues, state: nil)
        if state.nil?
          issues.length
        else
          issues.select {|issue| issue[:state] == state}.length
        end
      end

      def closed_issues_count
        return @closed_issues_count unless @closed_issues_count.nil?

        @closed_issues_count = count_issues(issues, state: "closed")
        @closed_issues_count
      end

      def open_issues_count
        return @open_issues_count unless @open_issues_count.nil?

        @open_issues_count = count_issues(issues, state: "open")
        @open_issues_count
      end

      def issue_closure_rate
        return 1.0 if count_issues(issues) == 0
        closed_issues_count.to_f / count_issues(issues).to_f
      end

      def closed_pull_request_count
        return @closed_pull_request_count unless @closed_pull_request_count.nil?

        @closed_pull_request_count = count_issues(pull_requests, state: "closed")
        @closed_pull_request_count
      end

      def open_pull_request_count
        return @open_pull_request_count unless @open_pull_request_count.nil?

        @open_pull_request_count = count_issues(pull_requests, state: "open")
        @open_pull_request_count
      end

      def pull_request_closure_rate
        return 1.0 if count_issues(pull_requests) == 0
        closed_pull_request_count.to_f / count_issues(pull_requests).to_f
      end

      def pull_requests
        return @pull_requests unless @pull_requests.nil?

        @pull_requests = @results[:issues].select { |issue| issue.key?(:pull_request) }
        @pull_requests
      end

      def issues
        return @issues unless @issues.nil?

        @issues = @results[:issues].select { |issue| !issue.key?(:pull_request) }
        @issues
      end

      def get_stats
        {
         "one_year_open_issues": open_issues_count,
         "one_year_closed_issues": closed_issues_count,
         "one_year_total_issues": issues.length,
         "one_year_issue_closure_rate": issue_closure_rate,
         "one_year_open_pull_requests": open_pull_request_count,
         "one_year_closed_pull_requests": closed_pull_request_count,
         "one_year_total_pull_requests": pull_requests.length,
         "one_year_pull_request_closure_rate": pull_request_closure_rate,
         "issues_stats_truncated": @results[:truncated]
        }
      end
    end
  end
end
