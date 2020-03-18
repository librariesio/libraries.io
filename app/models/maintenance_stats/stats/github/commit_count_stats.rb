# frozen_string_literal: true

module MaintenanceStats
  module Stats
    module Github
      class CommitsStat < BaseStat
        def get_stats
          {
            last_week_commits: pull_out_commit_count(@results, "lastWeek"),
            last_month_commits: pull_out_commit_count(@results, "lastMonth"),
            last_two_month_commits: pull_out_commit_count(@results, "lastTwoMonths"),
            last_year_commits: pull_out_commit_count(@results, "lastYear"),
            latest_commit: pull_out_latest_commit(@results),
          }
        end

        private

        def pull_out_commit_count(dataset, key)
          dataset.original_hash.dig("data", "repository", "defaultBranchRef", "target", key, "totalCount")
        end

        def pull_out_latest_commit(dataset)
          nodes = dataset.original_hash.dig("data", "repository", "defaultBranchRef", "target", "latestCommit", "nodes")
          Date.parse(nodes.first["committedDate"]) if nodes.present?
        end
      end

      class V3CommitsStat < BaseStat
        def get_stats
          {
            v3_last_week_commits: count_up_commits(0, 0),
            v3_last_4_weeks_commits: count_up_commits(0, 3),
            v3_last_8_weeks_commits: count_up_commits(0, 7),
            v3_last_52_weeks_commits: count_up_commits(0, 51),
          }
        end

        private

        def count_up_commits(start_index, finish_index)
          @results[:all][start_index..finish_index].sum if !@results.nil? && @results.key?(:all)
        end
      end
    end
  end
end
