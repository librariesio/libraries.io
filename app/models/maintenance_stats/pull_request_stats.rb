module MaintenanceStats
    class PullRequestRates < BaseStat
        def get_stats
            {
                "pull_request_acceptance": request_acceptance_rate,
                "closed_pull_request_count": closed_requests_count,
                "open_pull_request_count": open_requests_count,
                "merged_pull_request_count": merged_requests_count,
            }
        end

        def total_pull_requests_count
            closed_requests_count + open_requests_count + merged_requests_count
        end

        def request_acceptance_rate
            return 0.0 if total_pull_requests_count == 0
            (merged_requests_count * 100.0) / total_pull_requests_count
        end

        def closed_requests_count
            @results.data.repository.closed_pull_requests.total_count || 0
        end

        def open_requests_count
            @results.data.repository.open_pull_requests.total_count || 0
        end

        def merged_requests_count
            @results.data.repository.merged_pull_requests.total_count || 0
        end
    end
end