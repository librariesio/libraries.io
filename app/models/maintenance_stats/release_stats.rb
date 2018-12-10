class ReleaseStats
    attr_accessor :last_release_date, :release_data
    def initialize(dataset)
        @dataset = dataset

        @release_data = []
        @last_release_date = @dataset.data.repository.releases.nodes.first&.published_at 
    end

    def get_stats(now)
        last_week_releases = release_data.select {|release| release[:published_at] > now - 7}.count
        last_month_releases = release_data.select {|release| release[:published_at] > now - 30}.count
        last_two_month_releases = release_data.select {|release| release[:published_at] > now - 60}.count
        last_year_releases = release_data.select {|release| release[:published_at] > now - 365}.count
        {
            "last_release_date": last_release_date,
            "last_week_releases": last_week_releases,
            "last_month_releases": last_month_releases,
            "last_two_month_releases": last_two_month_releases,
            "last_year_releases": last_year_releases,
        }
    end

    def add_releases(dataset, end_date)
        has_next_page = dataset.data.repository.releases.page_info.has_next_page
        cursor = dataset.data.repository.releases.page_info.end_cursor

        dataset.data.repository.releases.nodes.each do |release|
            publish_date = DateTime.parse(release.published_at)
            if publish_date > end_date
                @release_data << { name: release.name, published_at: publish_date }
            else
                has_next_page = false
                break
            end
        end

        {
            has_next_page: has_next_page,
            cursor: cursor
        }
    end
end