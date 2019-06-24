module MaintenanceStats
    module Stats
        module Bitbucket
            class CommitsStat < MaintenanceStats::Stats::BaseStat
                def count_up_commits(dataset, since)
                    return nil if dataset.nil? || dataset.empty?
                    dataset.select {|commit| Date.parse(commit["date"]) >= since}.size
                end

                def get_stats
                    {
                        "last_week_commits": count_up_commits(@results, 1.week.ago),
                        "last_month_commits": count_up_commits(@results, 1.month.ago),
                        "last_two_month_commits": count_up_commits(@results, 2.months.ago),
                        "last_year_commits": count_up_commits(@results, 1.year.ago)
                    }
                end
            end
        end
    end
end