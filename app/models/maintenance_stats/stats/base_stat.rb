# frozen_string_literal: true
# class to set interface for implementing Stat classes
module MaintenanceStats
    module Stats
        class BaseStat
            def initialize(results)
                @results = results
            end

            def get_stats
                # should return a hash with keys as the category and value as the value to be saved
                raise NoMethodError("get_stats needs to be overwritten")
            end
        end
    end
end