# frozen_string_literal: true

module MaintenanceStats
  module Stats
    module Github
      class IssueStats < BaseStat
        def initialize(dataset)
          super(dataset)
          @now = DateTime.current
        end

        def get_stats
          return {} if @results.nil?

          {
            one_year_open_issues: open_issues_count,
            one_year_closed_issues: closed_issues_count,
            one_year_total_issues: total_issues_count,
            one_year_issue_closure_rate: issue_closure_rate,
            one_year_open_pull_requests: open_pull_request_count,
            one_year_closed_pull_requests: closed_pull_request_count,
            one_year_total_pull_requests: total_pull_request_count,
            one_year_pull_request_closure_rate: pull_request_closure_rate,
            issues_stats_truncated: false,
          }
        end

        private

        def total_issues_count
          open_issues_count + closed_issues_count
        end

        def closed_issues_count
          @closed_issues_count ||= @results.original_hash.dig("data", "repository", "closedIssues", "totalCount") || 0
        end

        def open_issues_count
          @open_issues_count ||= @results.original_hash.dig("data", "repository", "openIssues", "totalCount") || 0
        end

        def issue_closure_rate
          return 1.0 if total_issues_count == 0

          closed_issues_count.to_f / total_issues_count
        end

        def total_pull_request_count
          open_pull_request_count + closed_pull_request_count
        end

        def closed_pull_request_count
          @closed_pull_request_count ||= @results.original_hash.dig("data", "closedPullRequests", "issueCount") || 0
        end

        def open_pull_request_count
          @open_pull_request_count ||= @results.original_hash.dig("data", "openPullRequests", "issueCount") || 0
        end

        def pull_request_closure_rate
          return 1.0 if total_pull_request_count == 0

          closed_pull_request_count.to_f / total_pull_request_count
        end
      end
    end
  end
end
