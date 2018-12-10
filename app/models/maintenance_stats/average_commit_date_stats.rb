class AverageCommitDate
    attr_accessor :average_commit_date
    def initialize(dataset)
        @dataset = dataset

        @average_commit_date = average_recent_committed_at
    end

    def get_stats
        {
            "average_commit_date": average_commit_date,
        }
    end

    def average_recent_committed_at
        edges = @dataset.data.repository.default_branch_ref.target.history.edges
  
        dates = edges.map { |edge| Time.parse(edge.node.authored_date) }
        Time.at(dates.map(&:to_i).sum / dates.count)
    end
end