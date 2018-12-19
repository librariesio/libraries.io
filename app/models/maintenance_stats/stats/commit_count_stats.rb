module MaintenanceStats
    module Stats
        class BaseCommitCount < BaseStat
            def pull_out_commit_count(dataset)
                return nil if dataset.data.repository.nil? || dataset.data.repository.default_branch_ref.nil?
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

        class V3CommitsStat < BaseStat
            def count_up_commits(start_index, finish_index)
                if !@results.nil? && @results.key?(:all)
                    @results[:all][start_index..finish_index].sum
                end
            end

            def get_stats
                {
                    "v3_last_week_commits": count_up_commits(0, 0),
                    "v3_last_4_weeks_commits": count_up_commits(0, 3),
                    "v3_last_8_weeks_commits": count_up_commits(0, 7),
                    "v3_last_52_weeks_commits": count_up_commits(0, 51)
                }
            end
        end
    end
end