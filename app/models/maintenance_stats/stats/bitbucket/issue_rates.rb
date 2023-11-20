# frozen_string_literal: true

module MaintenanceStats
  module Stats
    module Bitbucket
      class IssueRates < MaintenanceStats::Stats::BaseStat
        def fetch_stats
          {
            one_year_open_issues: open_issues_count,
            one_year_closed_issues: closed_issues_count,
            one_year_total_issues: issues.length,
            one_year_issue_closure_rate: issue_closure_rate,
            one_year_open_pull_requests: open_pull_request_count,
            one_year_closed_pull_requests: closed_pull_request_count,
            one_year_total_pull_requests: pull_requests.length,
            one_year_pull_request_closure_rate: pull_request_closure_rate,
            issues_stats_truncated: false,
          }
        end

        private

        def count_issues(issues, state: nil)
          state.nil? ? issues.size : issues.where(state: state).size
        end

        def closed_issues_count
          @closed_issues_count ||= count_issues(issues, state: "closed")
        end

        def open_issues_count
          @open_issues_count ||= count_issues(issues, state: "open")
        end

        def issue_closure_rate
          return 1.0 if count_issues(issues) == 0

          closed_issues_count.to_f / count_issues(issues)
        end

        def closed_pull_request_count
          @closed_pull_request_count ||= count_issues(pull_requests, state: "closed")
        end

        def open_pull_request_count
          @open_pull_request_count ||= count_issues(pull_requests, state: "open")
        end

        def pull_request_closure_rate
          return 1.0 if count_issues(pull_requests) == 0

          closed_pull_request_count.to_f / count_issues(pull_requests)
        end

        def pull_requests
          @pull_requests ||= @results.where(pull_request: true)
        end

        def issues
          @issues ||= @results.where(pull_request: false)
        end
      end
    end
  end
end
