class CommitCounts
    attr_accessor :last_week_commits, :last_month_commits, :last_two_month_commits, :last_year_commits
    def initialize
        @last_week_commits = @last_two_week_commits = @last_month_commits = @last_year_commits = 0
    end

    def get_stats
        {
            "last_week_commits": last_week_commits,
            "last_month_commits": last_month_commits,
            "last_two_month_commits": last_two_month_commits,
            "last_year_commits": last_year_commits,
        }
    end

    def self.pull_out_count(dataset)
        return 0 if dataset.data.nil?
        dataset.data.repository.default_branch_ref.target.history.total_count
    end
end