module MaintenanceStats
  module Stats
    module Github
      class V3ContributorCountStats < BaseStat
        def get_stats
          {
            v3_last_week_contributors: count_up_contributors(1),
            v3_last_4_weeks_contributors: count_up_contributors(4),
            v3_last_8_weeks_contributors: count_up_contributors(8),
            v3_last_52_weeks_contributors: count_up_contributors(52)
          }
        end

        private

        def count_up_contributors(weeks_ago)
          @results.select{ |contributor| contributed?(contributor, weeks_ago) }.size
        end

        def contributed?(contributor, weeks_ago)
          # todo: verify weeks are actually within the time period?
          # this assumes the latest week is the last item in the weeks array for this contributor
          # count up the weeks counting backwards from the end of the array
          # return true if there is a commit in any of those weeks
          contributor.weeks[-1*weeks_ago..contributor.weeks.length].sum(&:c) > 0
        end
      end
    end
  end
end
