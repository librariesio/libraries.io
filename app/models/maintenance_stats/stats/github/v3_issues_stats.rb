module MaintenanceStats
  module Stats
    module Github
      class V3IssueStats < BaseStat
        def get_stats
          {
          one_year_open_issues: open_issues_count,
          one_year_closed_issues: closed_issues_count,
          one_year_total_issues: issues.length,
          one_year_issue_closure_rate: issue_closure_rate,
          one_year_open_pull_requests: open_pull_request_count,
          one_year_closed_pull_requests: closed_pull_request_count,
          one_year_total_pull_requests: pull_requests.length,
          one_year_pull_request_closure_rate: pull_request_closure_rate,
          issues_stats_truncated: @results[:truncated]
          }
        end

        private

        def count_issues(issues, state: nil)
          state.nil? ? issues.length : issues.select {|issue| issue[:state] == state}.length
        end

        def closed_issues_count
          @closed_issues_count ||= count_issues(issues, state: "closed")
        end

        def open_issues_count
          @open_issues_count ||= count_issues(issues, state: "open")
        end

        def issue_closure_rate
          return 1.0 if count_issues(issues) == 0
          closed_issues_count.to_f / count_issues(issues).to_f
        end

        def closed_pull_request_count
          @closed_pull_request_count ||= count_issues(pull_requests, state: "closed")
        end

        def open_pull_request_count
          @open_pull_request_count ||= count_issues(pull_requests, state: "open")
        end

        def pull_request_closure_rate
          return 1.0 if count_issues(pull_requests) == 0
          closed_pull_request_count.to_f / count_issues(pull_requests).to_f
        end

        def pull_requests
          @pull_requests ||= @results[:issues].select { |issue| issue.key?(:pull_request) }
        end

        def issues
          @issues ||= @results[:issues].select { |issue| !issue.key?(:pull_request) }
        end
      end
    end
  end
end
