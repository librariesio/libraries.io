module MaintenanceStats
  module Stats
    module Github
      class ReleaseStats < BaseStat
        def initialize(dataset)
          super(dataset)
          @now = DateTime.current
        end

        def get_stats
          return {} if @results.nil?
          
          last_week_releases = @results.select {|release| DateTime.parse(release.published_at) > @now - 1.week}.count
          last_month_releases = @results.select {|release| DateTime.parse(release.published_at) > @now - 1.month}.count
          last_two_month_releases = @results.select {|release| DateTime.parse(release.published_at) > @now - 2.months}.count
          last_year_releases = @results.select {|release| DateTime.parse(release.published_at) > @now - 1.year}.count
          stats = {
            last_release_date: last_release_date,
            last_week_releases: last_week_releases,
            last_month_releases: last_month_releases,
            last_two_month_releases: last_two_month_releases,
            last_year_releases: last_year_releases,
          }
        end

        private

        def last_release_date
          @results&.map { |node| DateTime.parse(node.published_at) }.first&.strftime('%FT%TZ')
        end
      end
    end
  end
end