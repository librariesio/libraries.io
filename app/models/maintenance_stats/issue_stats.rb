module MaintenanceStats
    class IssueRates < BaseStat
        def get_stats
            {
                "issue_closure_rate": issue_closure_rate,
                "closed_issue_count": closed_issues_count,
                "open_issue_count": open_issues_count,
            }
        end

        def total_issues_count
            closed_issues_count + open_issues_count
        end

        def issue_closure_rate
            return 0.0 if total_issues_count == 0
            (closed_issues_count * 100.0) / (open_issues_count + closed_issues_count)
        end

        def open_issues_count
            @results.data.repository.open_issues.total_count || 0
        end

        def closed_issues_count
            @results.data.repository.closed_issues.total_count || 0
        end
    end
end