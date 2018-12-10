class IssueRates
    attr_accessor :closed_issues_count, :open_issues_count
    def initialize(dataset)
        @dataset = dataset

        @closed_issues_count = 0
        @open_issues_count = 0

        @closed_issues_count = @dataset.data.repository.closed_issues.total_count
        @open_issues_count = @dataset.data.repository.open_issues.total_count
    end

    def get_stats
        {
            "issue_closure_rate": issue_closure_rate,
            "closed_issue_count": closed_issues_count,
            "open_issue_count": open_issues_count,
        }
    end

    def total_issues_count
        closed_issues_count + open_issues_count
    end

    def issue_closure_rate
        return 0.0 if total_issues_count == 0
        (closed_issues_count * 100.0) / (open_issues_count + closed_issues_count)
    end
end