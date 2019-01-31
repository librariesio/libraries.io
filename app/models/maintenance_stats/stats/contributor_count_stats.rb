module MaintenanceStats
  module Stats
    class V3ContributorCountStats < BaseStat

      def count_up_contributors(weeks_ago)
        @results.map do |contributor|
          if contributor.weeks[-1*weeks_ago..contributor.weeks.length].sum(&:c) > 0
            1
          else
            0
          end
        end.sum
      end

      def get_stats
        {
          "v3_last_week_contributors": count_up_contributors(1),
         "v3_last_4_weeks_contributors": count_up_contributors(4),
         "v3_last_8_weeks_contributors": count_up_contributors(8),
         "v3_last_52_weeks_contributors": count_up_contributors(52)
        }
      end
    end
  end
end
