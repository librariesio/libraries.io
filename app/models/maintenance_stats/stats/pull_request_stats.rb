module MaintenanceStats
    module Stats
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
                return 0 if closed_requests_count.nil? && open_requests_count.nil? && merged_requests_count.nil?
                closed_requests_count + open_requests_count + merged_requests_count
            end

            def request_acceptance_rate
                return 1.0 if total_pull_requests_count == 0
                merged_requests_count.to_f / total_pull_requests_count.to_f
            end

            def closed_requests_count
                @results.data.repository&.closed_pull_requests.total_count
            end

            def open_requests_count
                @results.data.repository&.open_pull_requests.total_count
            end

            def merged_requests_count
                @results.data.repository&.merged_pull_requests.total_count
            end
        end
    end
end