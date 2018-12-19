module MaintenanceStats
    module Stats
        class Contributors < BaseStat
            def get_stats
                {
                    "total_contributors": total_contributors,
                }
            end

            private

            def total_contributors
                @results.count unless @results.nil? || @results.blank?
            end
        end
    end
end