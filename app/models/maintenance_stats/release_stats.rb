module MaintenanceStats
    class ReleaseStats < BaseStat

        def initialize(dataset)
            super(dataset)
            @now = DateTime.now
        end

        def get_stats
            last_week_releases = @results.select {|release| release[:published_at] > @now - 7}.count
            last_month_releases = @results.select {|release| release[:published_at] > @now - 30}.count
            last_two_month_releases = @results.select {|release| release[:published_at] > @now - 60}.count
            last_year_releases = @results.select {|release| release[:published_at] > @now - 365}.count
            {
                "last_release_date": last_release_date,
                "last_week_releases": last_week_releases,
                "last_month_releases": last_month_releases,
                "last_two_month_releases": last_two_month_releases,
                "last_year_releases": last_year_releases,
            }
        end

        def last_release_date
            @results.first&.published_at 
        end
    end
end