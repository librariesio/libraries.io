module MaintenanceStats
    class BaseCommitCount < BaseStat
        def pull_out_commit_count(dataset)
            return 0 if dataset.data.nil?
            dataset.data.repository.default_branch_ref.target.history.total_count
        end
    end

    class LastWeekCommitsStat < BaseCommitCount
        def get_stats
            {
                "last_week_commits": pull_out_commit_count(@results)
            }
        end
    end

    class LastMonthCommitsStat < BaseCommitCount
        def get_stats
            {
                "last_month_commits": pull_out_commit_count(@results)
            }
        end
    end

    class LastTwoMonthCommitsStat < BaseCommitCount
        def get_stats
            {
                "last_two_month_commits": pull_out_commit_count(@results)
            }
        end
    end

    class LastYearCommitsStat < BaseCommitCount
        def get_stats
            {
                "last_year_commits": pull_out_commit_count(@results)
            }
        end
    end
end