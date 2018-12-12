module MaintenanceStats
    class AverageCommitDate < BaseStat

        def get_stats
            {
                "average_commit_date": average_commit_date,
            }
        end

        private 
        
        def average_commit_date
            edges = @results.data.repository.default_branch_ref.target.history.edges
    
            dates = edges.map { |edge| Time.parse(edge.node.authored_date) }
            Time.at(dates.map(&:to_i).sum / dates.count)
        end
    end
end