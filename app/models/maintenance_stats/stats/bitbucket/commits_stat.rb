# frozen_string_literal: true

module MaintenanceStats
  module Stats
    module Bitbucket
      class CommitsStat < MaintenanceStats::Stats::BaseStat
        def initialize(dataset)
          super(dataset)
          @now = DateTime.current
        end

        def fetch_stats
          {
            last_week_commits: count_up_commits(@results, @now - 7),
            last_month_commits: count_up_commits(@results, @now - 30),
            last_two_month_commits: count_up_commits(@results, @now - 60),
            last_year_commits: count_up_commits(@results, @now - 365),
            latest_commit: latest_commit(@results),
          }
        end

        private

        def count_up_commits(dataset, since)
          return unless dataset.present?

          dataset.select { |commit| Date.parse(commit["date"]) >= since }.size
        end

        def latest_commit(dataset)
          latest = dataset&.sort_by { |commit| commit["date"] }&.last
          Date.parse(latest["date"]) if latest.present? && latest["date"].present?
        end
      end
    end
  end
end
